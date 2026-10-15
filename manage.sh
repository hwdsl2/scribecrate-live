#!/bin/bash
#
# https://github.com/hwdsl2/scribecrate-live
#
# Copyright (C) 2026 Lin Song <linsongui@gmail.com>
#
# This work is licensed under the MIT License
# See: https://opensource.org/licenses/MIT

export PATH="/opt/venv/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

WHISPERLIVE_DATA="/var/lib/whisper-live"
PORT_FILE="${WHISPERLIVE_DATA}/.ws_port"
REST_PORT_FILE="${WHISPERLIVE_DATA}/.rest_port"
MODEL_FILE="${WHISPERLIVE_DATA}/.model"
SERVER_ADDR_FILE="${WHISPERLIVE_DATA}/.server_addr"
API_KEY_FILE="${WHISPERLIVE_DATA}/.api_key"
AUTH_ENABLED_FILE="${WHISPERLIVE_DATA}/.auth_enabled"

exiterr() { echo "Error: $1" >&2; exit 1; }

show_usage() {
  local exit_code="${2:-1}"
  if [ -n "$1" ]; then
    echo "Error: $1" >&2
  fi
  cat 1>&2 <<'EOF'

ScribeCrate Live - Server Management
https://github.com/hwdsl2/scribecrate-live

Usage: docker exec <container> whisper_live_manage [options]

Options:
  --showinfo                           show server info (model, endpoints)
  --showkey                            show the API key, if configured
  --getkey                             output the API key (machine-readable, no decoration)
  --listmodels                         list available Whisper model names and sizes
  --downloadmodel <model>              pre-download a model to the cache volume

  -h, --help                           show this help message and exit

Available models: tiny, tiny.en, base, base.en, small, small.en,
                  medium, medium.en, large-v1, large-v2, large-v3,
                  large-v3-turbo (or: turbo)

To switch the active model, set WHISPERLIVE_MODEL=<name> and restart the container.
Use '--downloadmodel' to pre-download a model before switching, avoiding a
delay on the next container start.

Examples:
  docker exec whisper-live whisper_live_manage --showinfo
  docker exec whisper-live whisper_live_manage --showkey
  docker exec whisper-live whisper_live_manage --getkey
  docker exec whisper-live whisper_live_manage --listmodels
  docker exec whisper-live whisper_live_manage --downloadmodel large-v3
  docker exec whisper-live whisper_live_manage --downloadmodel large-v3-turbo

EOF
  exit "$exit_code"
}

check_container() {
  if [ ! -f "/.dockerenv" ] && [ ! -f "/run/.containerenv" ] \
    && [ -z "$KUBERNETES_SERVICE_HOST" ] \
    && ! head -n 1 /proc/1/sched 2>/dev/null | grep -q '^run\.sh '; then
    exiterr "This script must be run inside a container (e.g. Docker, Podman)."
  fi
}

load_config() {
  if [ -z "$WHISPERLIVE_PORT" ]; then
    if [ -f "$PORT_FILE" ]; then
      WHISPERLIVE_PORT=$(cat "$PORT_FILE")
    else
      WHISPERLIVE_PORT=9090
    fi
  fi

  if [ -z "$WHISPERLIVE_REST_PORT" ]; then
    if [ -f "$REST_PORT_FILE" ]; then
      WHISPERLIVE_REST_PORT=$(cat "$REST_PORT_FILE")
    else
      WHISPERLIVE_REST_PORT=8000
    fi
  fi

  if [ -z "$WHISPERLIVE_MODEL" ]; then
    if [ -f "$MODEL_FILE" ]; then
      WHISPERLIVE_MODEL=$(cat "$MODEL_FILE")
    else
      WHISPERLIVE_MODEL=base
    fi
  fi

  if [ -f "$SERVER_ADDR_FILE" ]; then
    SERVER_ADDR=$(cat "$SERVER_ADDR_FILE")
  else
    SERVER_ADDR="<server ip>"
  fi

  if [ -f "$AUTH_ENABLED_FILE" ]; then
    WHISPERLIVE_AUTH_ENABLED=$(cat "$AUTH_ENABLED_FILE")
  fi

  if [ "$WHISPERLIVE_AUTH_ENABLED" != 0 ] && [ -z "$WHISPERLIVE_API_KEY" ] && [ -f "$API_KEY_FILE" ]; then
    WHISPERLIVE_API_KEY=$(cat "$API_KEY_FILE")
  fi

  if [ -z "$WHISPERLIVE_AUTH_ENABLED" ]; then
    if [ -n "$WHISPERLIVE_API_KEY" ]; then
      WHISPERLIVE_AUTH_ENABLED=1
    else
      WHISPERLIVE_AUTH_ENABLED=0
    fi
  fi
}

check_server() {
  if [ -n "$WHISPERLIVE_API_KEY" ]; then
    if curl -sf --max-time 5 -H "Authorization: Bearer ${WHISPERLIVE_API_KEY}" \
        "http://127.0.0.1:${WHISPERLIVE_REST_PORT}/docs" >/dev/null 2>&1; then
      return 0
    fi
  elif curl -sf --max-time 5 "http://127.0.0.1:${WHISPERLIVE_REST_PORT}/docs" >/dev/null 2>&1; then
    return 0
  fi
  exiterr "ScribeCrate Live server is not responding on REST port ${WHISPERLIVE_REST_PORT}. Is the container fully started?"
}

parse_args() {
  show_info=0
  show_key=0
  get_key=0
  list_models=0
  download_model=0
  model_to_download=""

  while [ "$#" -gt 0 ]; do
    case "$1" in
      --showinfo)
        show_info=1
        shift
        ;;
      --showkey)
        show_key=1
        shift
        ;;
      --getkey)
        get_key=1
        shift
        ;;
      --listmodels)
        list_models=1
        shift
        ;;
      --downloadmodel)
        download_model=1
        model_to_download="${2:-}"
        shift
        [ "$#" -gt 0 ] && shift
        ;;
      -h|--help)
        show_usage "" 0
        ;;
      *)
        show_usage "Unknown parameter: $1"
        ;;
    esac
  done
}

check_args() {
  local action_count
  action_count=$((show_info + show_key + get_key + list_models + download_model))

  if [ "$action_count" -eq 0 ]; then
    show_usage
  fi
  if [ "$action_count" -gt 1 ]; then
    show_usage "Specify only one action at a time."
  fi

  if [ "$download_model" = 1 ] && [ -z "$model_to_download" ]; then
    exiterr "Missing model name. Usage: --downloadmodel <model>"
  fi
}

do_show_key() {
  if [ "$WHISPERLIVE_AUTH_ENABLED" != 1 ]; then
    exiterr "API key authentication is disabled for this container."
  fi

  if [ -z "$WHISPERLIVE_API_KEY" ]; then
    if [ -f "$API_KEY_FILE" ]; then
      WHISPERLIVE_API_KEY=$(cat "$API_KEY_FILE")
    else
      exiterr "API key not found. Authentication may be disabled for this container."
    fi
  fi

  echo
  echo "==========================================================="
  echo " ScribeCrate Live API key"
  echo "==========================================================="
  echo "${WHISPERLIVE_API_KEY}"
  echo "==========================================================="
  echo
  echo "REST API:  -H \"Authorization: Bearer ${WHISPERLIVE_API_KEY}\""
  echo "WebSocket: ws://<server-ip>:${WHISPERLIVE_PORT}?token=${WHISPERLIVE_API_KEY}"
  echo
}

do_get_key() {
  if [ "$WHISPERLIVE_AUTH_ENABLED" != 1 ]; then
    exit 1
  fi

  if [ -z "$WHISPERLIVE_API_KEY" ]; then
    if [ -f "$API_KEY_FILE" ]; then
      WHISPERLIVE_API_KEY=$(cat "$API_KEY_FILE")
    else
      exit 1
    fi
  fi

  printf '%s' "$WHISPERLIVE_API_KEY"
}

do_show_info() {
  echo
  echo "==========================================================="
  echo " ScribeCrate Live Real-Time Transcription Server"
  echo "==========================================================="
  echo " Active model: $WHISPERLIVE_MODEL"
  echo " WebSocket:    ws://${SERVER_ADDR}:${WHISPERLIVE_PORT}"
  echo " REST API:     http://${SERVER_ADDR}:${WHISPERLIVE_REST_PORT}"
  echo "==========================================================="
  echo
  echo "WebSocket streaming endpoint:"
  if [ "$WHISPERLIVE_AUTH_ENABLED" = 1 ]; then
    echo "  ws://${SERVER_ADDR}:${WHISPERLIVE_PORT}?token=<api-key>"
  else
    echo "  ws://${SERVER_ADDR}:${WHISPERLIVE_PORT}"
  fi
  echo
  echo "REST API endpoints:"
  echo "  POST http://${SERVER_ADDR}:${WHISPERLIVE_REST_PORT}/v1/audio/transcriptions"
  echo "  GET  http://${SERVER_ADDR}:${WHISPERLIVE_REST_PORT}/docs     (interactive docs)"
  echo "  Docs, OpenAPI schema, and health checks are public."
  if [ "$WHISPERLIVE_AUTH_ENABLED" = 1 ]; then
    echo "  Transcription requests require Authorization: Bearer <api-key>."
  fi
  echo
  echo "Example file transcription (REST):"
  echo "  curl http://${SERVER_ADDR}:${WHISPERLIVE_REST_PORT}/v1/audio/transcriptions \\"
  if [ "$WHISPERLIVE_AUTH_ENABLED" = 1 ]; then
    echo "    -H \"Authorization: Bearer <api-key>\" \\"
  fi
  echo "    -F file=@audio.mp3 -F model=whisper-1"
  if [ "$WHISPERLIVE_AUTH_ENABLED" = 1 ]; then
    echo
    echo "Use '--showkey' to display the API key."
  fi
  echo
  echo "To change the active model:"
  echo "  1. Pre-download: docker exec <container> whisper_live_manage --downloadmodel <name>"
  echo "  2. Set WHISPERLIVE_MODEL=<name> in your env file and restart the container."
  echo
}

do_list_models() {
  cat <<'EOF'

Available Whisper models:

  Name              Disk     RAM (approx)   Notes
  ----              ----     ------------   -----
  tiny              ~75 MB   ~250 MB        Fastest; lower accuracy
  tiny.en           ~75 MB   ~250 MB        English-only variant
  base              ~145 MB  ~500 MB        Good balance — default
  base.en           ~145 MB  ~500 MB        English-only variant
  small             ~465 MB  ~1.5 GB        Better accuracy
  small.en          ~465 MB  ~1.5 GB        English-only variant
  medium            ~1.5 GB  ~5 GB          High accuracy
  medium.en         ~1.5 GB  ~5 GB          English-only variant
  large-v1          ~3 GB    ~10 GB         Older large model
  large-v2          ~3 GB    ~10 GB         Very high accuracy
  large-v3          ~3 GB    ~10 GB         Best accuracy (recommended for quality)
  large-v3-turbo    ~1.6 GB  ~6 GB          Fast + high accuracy (best overall upgrade)
  turbo             ~1.6 GB  ~6 GB          Alias for large-v3-turbo

Notes:
  - English-only (.en) variants are slightly faster for English audio.
  - large-v3-turbo (or: turbo) is recommended over large-v3 for most use
    cases: comparable accuracy with significantly lower resource usage.
  - Most models are downloaded from HuggingFace (Systran/faster-whisper-*);
    large-v3-turbo/turbo use mobiuslabsgmbh/faster-whisper-large-v3-turbo.
    All are cached in the /var/lib/whisper-live Docker volume.
  - INT8 quantization (default) reduces RAM usage by approximately 50%.

Use '--downloadmodel <name>' to pre-download a model before switching.

EOF
}

do_download_model() {
  # Block download if WHISPERLIVE_LOCAL_ONLY is set
  if [ -n "$WHISPERLIVE_LOCAL_ONLY" ]; then
    exiterr "WHISPERLIVE_LOCAL_ONLY is set — model downloads are disabled. Unset it to allow downloads."
  fi

  # Validate model name
  case "$model_to_download" in
    tiny|tiny.en|base|base.en|small|small.en|medium|medium.en|\
    large-v1|large-v2|large-v3|large-v3-turbo|turbo) ;;
    *)
      exiterr "Unknown model '$model_to_download'. Run '--listmodels' to see valid names."
      ;;
  esac

  echo
  echo "Downloading model '${model_to_download}' to /var/lib/whisper-live..."
  echo "This may take several minutes depending on model size and network speed."
  echo

  export HF_HOME=/var/lib/whisper-live
  # Ensure offline mode is not set when explicitly downloading
  unset HF_HUB_OFFLINE

  _MODEL="$model_to_download" python3 - << 'PYEOF'
import os, sys

model_name = os.environ["_MODEL"]
cache_dir  = os.environ.get("HF_HOME", "/var/lib/whisper-live")

try:
    from faster_whisper import WhisperModel
    print(f"  Downloading '{model_name}' (compute_type=int8) ...")
    sys.stdout.flush()
    WhisperModel(
        model_name,
        device="cpu",
        compute_type="int8",
        download_root=cache_dir,
    )
    print(f"  Model '{model_name}' downloaded successfully.")
    print(f"  Cache location: {cache_dir}")
except Exception as exc:
    print(f"Error: {exc}", file=sys.stderr)
    sys.exit(1)
PYEOF

  echo
  echo "To activate this model, set WHISPERLIVE_MODEL=${model_to_download} in your"
  echo "env file (whisper-live.env) and restart the container."
  echo
}

check_container
load_config
parse_args "$@"
check_args

if [ "$show_info" = 1 ]; then
  check_server
  do_show_info
  exit 0
fi

if [ "$show_key" = 1 ]; then
  do_show_key
  exit 0
fi

if [ "$get_key" = 1 ]; then
  do_get_key
  exit 0
fi

if [ "$list_models" = 1 ]; then
  do_list_models
  exit 0
fi

if [ "$download_model" = 1 ]; then
  do_download_model
  exit 0
fi
