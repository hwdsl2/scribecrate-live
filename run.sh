#!/bin/bash
#
# Docker script to configure and start a ScribeCrate Live real-time transcription server
#
# DO NOT RUN THIS SCRIPT ON YOUR PC OR MAC! THIS IS ONLY MEANT TO BE RUN
# IN A CONTAINER!
#
# This file is part of ScribeCrate Live image, available at:
# https://github.com/hwdsl2/scribecrate-live
#
# Copyright (C) 2026 Lin Song <linsongui@gmail.com>
#
# This work is licensed under the MIT License
# See: https://opensource.org/licenses/MIT

export PATH="/opt/venv/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

exiterr()  { echo "Error: $1" >&2; exit 1; }
nospaces() { printf '%s' "$1" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'; }
noquotes() { printf '%s' "$1" | sed -e 's/^"\(.*\)"$/\1/' -e "s/^'\(.*\)'$/\1/"; }

check_port() {
  printf '%s' "$1" | tr -d '\n' | grep -Eq '^[0-9]+$' \
  && [ "$1" -ge 1 ] && [ "$1" -le 65535 ]
}

check_ip() {
  IP_REGEX='^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$'
  printf '%s' "$1" | tr -d '\n' | grep -Eq "$IP_REGEX"
}

fetch_public_ip() {
  local ip_addr ip_url
  for ip_url in https://ipv4.icanhazip.com https://api.ipify.org; do
    ip_addr=$(curl -q -4fsS --max-time 10 "$ip_url" 2>/dev/null) || continue
    ip_addr=${ip_addr%$'\r'}
    [[ "$ip_addr" != *$'\n'* && "$ip_addr" != *$'\r'* ]] || continue
    if check_ip "$ip_addr"; then
      printf '%s' "$ip_addr"
      return 0
    fi
  done
  return 1
}

# Source bind-mounted env file if present (takes precedence over --env-file)
if [ -f /whisper-live.env ]; then
  # shellcheck disable=SC1091
  . /whisper-live.env
fi

if [ ! -f "/.dockerenv" ] && [ ! -f "/run/.containerenv" ] \
  && [ -z "$KUBERNETES_SERVICE_HOST" ] \
  && ! head -n 1 /proc/1/sched 2>/dev/null | grep -q '^run\.sh '; then
  exiterr "This script ONLY runs in a container (e.g. Docker, Podman)."
fi

WHISPERLIVE_API_KEY_WAS_SET=${WHISPERLIVE_API_KEY+x}

# Read and sanitize environment variables
WHISPERLIVE_MODEL=$(nospaces "$WHISPERLIVE_MODEL")
WHISPERLIVE_MODEL=$(noquotes "$WHISPERLIVE_MODEL")
WHISPERLIVE_LANGUAGE=$(nospaces "$WHISPERLIVE_LANGUAGE")
WHISPERLIVE_LANGUAGE=$(noquotes "$WHISPERLIVE_LANGUAGE")
WHISPERLIVE_PORT=$(nospaces "$WHISPERLIVE_PORT")
WHISPERLIVE_PORT=$(noquotes "$WHISPERLIVE_PORT")
WHISPERLIVE_REST_PORT=$(nospaces "$WHISPERLIVE_REST_PORT")
WHISPERLIVE_REST_PORT=$(noquotes "$WHISPERLIVE_REST_PORT")
WHISPERLIVE_MAX_CLIENTS=$(nospaces "$WHISPERLIVE_MAX_CLIENTS")
WHISPERLIVE_MAX_CLIENTS=$(noquotes "$WHISPERLIVE_MAX_CLIENTS")
WHISPERLIVE_MAX_CONNECTION_TIME=$(nospaces "$WHISPERLIVE_MAX_CONNECTION_TIME")
WHISPERLIVE_MAX_CONNECTION_TIME=$(noquotes "$WHISPERLIVE_MAX_CONNECTION_TIME")
WHISPERLIVE_USE_VAD=$(nospaces "$WHISPERLIVE_USE_VAD")
WHISPERLIVE_USE_VAD=$(noquotes "$WHISPERLIVE_USE_VAD")
WHISPERLIVE_THREADS=$(nospaces "$WHISPERLIVE_THREADS")
WHISPERLIVE_THREADS=$(noquotes "$WHISPERLIVE_THREADS")
WHISPERLIVE_LOG_LEVEL=$(nospaces "$WHISPERLIVE_LOG_LEVEL")
WHISPERLIVE_LOG_LEVEL=$(noquotes "$WHISPERLIVE_LOG_LEVEL")
WHISPERLIVE_API_KEY=$(nospaces "$WHISPERLIVE_API_KEY")
WHISPERLIVE_API_KEY=$(noquotes "$WHISPERLIVE_API_KEY")
WHISPERLIVE_LOCAL_ONLY=$(nospaces "$WHISPERLIVE_LOCAL_ONLY")
WHISPERLIVE_LOCAL_ONLY=$(noquotes "$WHISPERLIVE_LOCAL_ONLY")

# Apply defaults
[ -z "$WHISPERLIVE_MODEL" ]              && WHISPERLIVE_MODEL=base
[ -z "$WHISPERLIVE_LANGUAGE" ]           && WHISPERLIVE_LANGUAGE=auto
[ -z "$WHISPERLIVE_PORT" ]               && WHISPERLIVE_PORT=9090
[ -z "$WHISPERLIVE_REST_PORT" ]          && WHISPERLIVE_REST_PORT=8000
[ -z "$WHISPERLIVE_MAX_CLIENTS" ]        && WHISPERLIVE_MAX_CLIENTS=4
[ -z "$WHISPERLIVE_MAX_CONNECTION_TIME" ] && WHISPERLIVE_MAX_CONNECTION_TIME=600
[ -z "$WHISPERLIVE_USE_VAD" ]            && WHISPERLIVE_USE_VAD=true
[ -z "$WHISPERLIVE_THREADS" ]            && WHISPERLIVE_THREADS=2
[ -z "$WHISPERLIVE_LOG_LEVEL" ]          && WHISPERLIVE_LOG_LEVEL=INFO

# Validate WebSocket port
if ! check_port "$WHISPERLIVE_PORT"; then
  exiterr "WHISPERLIVE_PORT must be an integer between 1 and 65535."
fi

# Validate REST port
if ! check_port "$WHISPERLIVE_REST_PORT"; then
  exiterr "WHISPERLIVE_REST_PORT must be an integer between 1 and 65535."
fi

if [ "$WHISPERLIVE_PORT" = "$WHISPERLIVE_REST_PORT" ]; then
  exiterr "WHISPERLIVE_PORT and WHISPERLIVE_REST_PORT must be different."
fi

# Validate model name
case "$WHISPERLIVE_MODEL" in
  tiny|tiny.en|base|base.en|small|small.en|medium|medium.en|\
  large-v1|large-v2|large-v3|large-v3-turbo|turbo) ;;
  *) exiterr "WHISPERLIVE_MODEL '$WHISPERLIVE_MODEL' is not recognized. Valid options: tiny, tiny.en, base, base.en, small, small.en, medium, medium.en, large-v1, large-v2, large-v3, large-v3-turbo, turbo" ;;
esac

# Validate log level
case "$WHISPERLIVE_LOG_LEVEL" in
  DEBUG|INFO|WARNING|ERROR|CRITICAL) ;;
  *) exiterr "WHISPERLIVE_LOG_LEVEL must be one of: DEBUG, INFO, WARNING, ERROR, CRITICAL." ;;
esac

# Validate thread count
if ! printf '%s' "$WHISPERLIVE_THREADS" | grep -Eq '^[1-9][0-9]*$'; then
  exiterr "WHISPERLIVE_THREADS must be a positive integer."
fi

# Validate max clients
if ! printf '%s' "$WHISPERLIVE_MAX_CLIENTS" | grep -Eq '^[1-9][0-9]*$'; then
  exiterr "WHISPERLIVE_MAX_CLIENTS must be a positive integer."
fi

# Validate max connection time
if ! printf '%s' "$WHISPERLIVE_MAX_CONNECTION_TIME" | grep -Eq '^[1-9][0-9]*$'; then
  exiterr "WHISPERLIVE_MAX_CONNECTION_TIME must be a positive integer (seconds)."
fi

mkdir -p /var/lib/whisper-live

DATA_DIR="/var/lib/whisper-live"
API_KEY_FILE="${DATA_DIR}/.api_key"
AUTH_ENABLED_FILE="${DATA_DIR}/.auth_enabled"
AUTO_API_KEY_MARKER="${DATA_DIR}/.auto_api_key_created"
USAGE_STATE_DIR="${DATA_DIR}/.whisperlive-usage"
USAGE_BASE_URL=${WHISPERLIVE_USAGE_BASE_URL:-https://github.com/hwdsl2/ai-stack-extras/releases/download/v1.0.0}
data_mounted=false
data_existing=false

if grep -q " ${DATA_DIR} " /proc/mounts 2>/dev/null; then
  data_mounted=true
fi
if $data_mounted && find "$DATA_DIR" -mindepth 1 -maxdepth 1 -print -quit 2>/dev/null | grep -q .; then
  data_existing=true
fi

usage_arch() {
  local arch
  arch=$(uname -m 2>/dev/null || printf 'unknown')
  case "$arch" in
    x86_64|amd64) printf 'amd64' ;;
    aarch64|arm64) printf 'arm64' ;;
    *) printf 'other' ;;
  esac
}

write_usage_state() {
  local state_file version tmp_file
  state_file=$1
  version=$2
  mkdir -p "$USAGE_STATE_DIR"
  tmp_file=$(mktemp "$USAGE_STATE_DIR/.usage.XXXXXX")
  printf '%s\n' "$version" > "$tmp_file"
  chmod 0644 "$tmp_file" 2>/dev/null || true
  mv "$tmp_file" "$state_file"
}

fetch_usage_asset() {
  local asset base_url
  asset=$1
  base_url=${USAGE_BASE_URL%/}
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL --max-time 5 -o /dev/null "$base_url/$asset" >/dev/null 2>&1
  elif command -v wget >/dev/null 2>&1; then
    wget -q -T 5 -O /dev/null "$base_url/$asset" >/dev/null 2>&1
  else
    return 1
  fi
}

read_state_value() {
  [ -r "$1" ] || return 0
  tr -d '[:space:]' < "$1"
}

report_usage_counts() {
  local current_version accel arch state_file last_version action

  [ "${WHISPERLIVE_DISABLE_USAGE_COUNTS:-0}" != "1" ] || return 0
  $data_mounted || return 0

  current_version="${IMAGE_FLAVOR:-unknown}-${IMAGE_VER:-unknown}"
  case "${IMAGE_FLAVOR:-}" in
    cuda) accel=cuda ;;
    *) accel=cpu ;;
  esac
  arch=$(usage_arch)

  state_file="$USAGE_STATE_DIR/whisperlive.version"
  last_version=$(read_state_value "$state_file")
  action=

  if [ -z "$last_version" ]; then
    if $data_existing; then
      action=upgrade
    else
      action=deploy
    fi
  elif [ "$last_version" != "$current_version" ]; then
    action=upgrade
  fi

  if [ -n "$action" ]; then
    if fetch_usage_asset "cu-v1-whisperlive-$action-$accel-$arch"; then
      write_usage_state "$state_file" "$current_version"
    fi
  fi
}

if [ -n "$WHISPERLIVE_API_KEY" ]; then
  printf '%s' "$WHISPERLIVE_API_KEY" > "$API_KEY_FILE"
  chmod 600 "$API_KEY_FILE"
elif [ -z "$WHISPERLIVE_API_KEY_WAS_SET" ] && [ -f "$API_KEY_FILE" ]; then
  WHISPERLIVE_API_KEY=$(cat "$API_KEY_FILE")
elif [ -z "$WHISPERLIVE_API_KEY_WAS_SET" ] && $data_mounted && ! $data_existing; then
  WHISPERLIVE_API_KEY="whisperlive-$(head -c 32 /dev/urandom | od -A n -t x1 | tr -d ' \n' | head -c 48)"
  printf '%s' "$WHISPERLIVE_API_KEY" > "$API_KEY_FILE"
  chmod 600 "$API_KEY_FILE"
  printf '%s\n' "true" > "$AUTO_API_KEY_MARKER"
  chmod 600 "$AUTO_API_KEY_MARKER"
fi
if [ -n "$WHISPERLIVE_API_KEY" ]; then
  printf '%s' "1" > "$AUTH_ENABLED_FILE"
else
  printf '%s' "0" > "$AUTH_ENABLED_FILE"
fi

# Determine server address for display
public_ip=$(fetch_public_ip) || public_ip=""
if check_ip "$public_ip"; then
  server_addr="$public_ip"
else
  server_addr="<server ip>"
fi

# Export all config for the Python server
export WHISPERLIVE_MODEL
export WHISPERLIVE_LANGUAGE
export WHISPERLIVE_PORT
export WHISPERLIVE_REST_PORT
export WHISPERLIVE_MAX_CLIENTS
export WHISPERLIVE_MAX_CONNECTION_TIME
export WHISPERLIVE_USE_VAD
export WHISPERLIVE_THREADS
export WHISPERLIVE_LOG_LEVEL
export WHISPERLIVE_API_KEY
export WHISPERLIVE_LOCAL_ONLY
# Point faster-whisper / HuggingFace Hub at the persistent Docker volume
export HF_HOME=/var/lib/whisper-live
export HF_HUB_CACHE=/var/lib/whisper-live
export OMP_NUM_THREADS="$WHISPERLIVE_THREADS"
# When local-only mode is set, tell HuggingFace Hub to work fully offline
if [ -n "$WHISPERLIVE_LOCAL_ONLY" ]; then
  export HF_HUB_OFFLINE=1
fi

# Persist config values so whisper_live_manage can read them without the env file
printf '%s' "$WHISPERLIVE_PORT"      > /var/lib/whisper-live/.ws_port
printf '%s' "$WHISPERLIVE_REST_PORT" > /var/lib/whisper-live/.rest_port
printf '%s' "$WHISPERLIVE_MODEL"     > /var/lib/whisper-live/.model
printf '%s' "$server_addr"           > /var/lib/whisper-live/.server_addr

echo
echo "ScribeCrate Live - https://github.com/hwdsl2/scribecrate-live"

if ! grep -q " /var/lib/whisper-live " /proc/mounts 2>/dev/null; then
  echo
  echo "Note: /var/lib/whisper-live is not mounted. Model files will be lost on"
  echo "      container removal. Mount a Docker volume at /var/lib/whisper-live"
  echo "      to persist the downloaded model across container restarts."
  if [ -z "$WHISPERLIVE_API_KEY" ] && [ -z "$WHISPERLIVE_API_KEY_WAS_SET" ]; then
    echo "      API key authentication was not auto-enabled because the"
    echo "      data directory is not persistent."
  fi
elif [ -z "$WHISPERLIVE_API_KEY" ] && [ -z "$WHISPERLIVE_API_KEY_WAS_SET" ] && $data_existing; then
  echo
  echo "Warning: Existing ScribeCrate Live data was found but no API key is configured."
  echo "         Preserving no-auth behavior for backward compatibility."
  echo "         Set WHISPERLIVE_API_KEY to enable authentication."
fi

echo
echo "Starting ScribeCrate Live real-time transcription server..."
echo "  Model:          $WHISPERLIVE_MODEL"
echo "  Language:       $WHISPERLIVE_LANGUAGE"
echo "  WebSocket port: $WHISPERLIVE_PORT"
echo "  REST API port:  $WHISPERLIVE_REST_PORT"
echo "  Max clients:    $WHISPERLIVE_MAX_CLIENTS"
echo "  VAD:            $WHISPERLIVE_USE_VAD"
if [ -n "$WHISPERLIVE_LOCAL_ONLY" ]; then
  echo "  Mode:           local-only (no HuggingFace downloads)"
fi

if [ -z "$WHISPERLIVE_LOCAL_ONLY" ]; then
  _model_in_cache() {
    local m="$1"
    [ -d "/var/lib/whisper-live/models--Systran--faster-whisper-${m}" ] && return 0
    [ -d "/var/lib/whisper-live/models--openai--whisper-${m}" ] && return 0
    case "$m" in
      large-v3-turbo|turbo)
        [ -d "/var/lib/whisper-live/models--mobiuslabsgmbh--faster-whisper-large-v3-turbo" ] && return 0
        ;;
    esac
    return 1
  }
  if ! _model_in_cache "$WHISPERLIVE_MODEL"; then
    echo
    echo "Note: Model '$WHISPERLIVE_MODEL' not found in cache. It will be downloaded"
    echo "      from HuggingFace on first client connection. This may take several minutes."
  fi
fi
echo

# Graceful shutdown
cleanup() {
  echo
  echo "Stopping ScribeCrate Live server..."
  kill "${SERVER_PID:-}" 2>/dev/null
  wait "${SERVER_PID:-}" 2>/dev/null
  exit 0
}
trap cleanup INT TERM

# Map model names to HuggingFace repo IDs.
# faster_whisper_custom_model_path must contain '/' to bypass upstream path validation,
# and faster-whisper accepts HuggingFace repo IDs (org/repo) directly.
_model_to_hf_repo() {
  case "$1" in
    tiny)             echo "Systran/faster-whisper-tiny" ;;
    tiny.en)          echo "Systran/faster-whisper-tiny.en" ;;
    base)             echo "Systran/faster-whisper-base" ;;
    base.en)          echo "Systran/faster-whisper-base.en" ;;
    small)            echo "Systran/faster-whisper-small" ;;
    small.en)         echo "Systran/faster-whisper-small.en" ;;
    medium)           echo "Systran/faster-whisper-medium" ;;
    medium.en)        echo "Systran/faster-whisper-medium.en" ;;
    large-v1)         echo "Systran/faster-whisper-large-v1" ;;
    large-v2)         echo "Systran/faster-whisper-large-v2" ;;
    large-v3)         echo "Systran/faster-whisper-large-v3" ;;
    large-v3-turbo|turbo) echo "mobiuslabsgmbh/faster-whisper-large-v3-turbo" ;;
    *)                echo "Systran/faster-whisper-${1}" ;;
  esac
}
_hf_repo=$(_model_to_hf_repo "$WHISPERLIVE_MODEL")
export _HF_REPO="$_hf_repo"

# Start the ScribeCrate Live server in the background
python3 -c "
import sys, os, logging
from whisper_live.server import TranscriptionServer
# Override log level after module import (server.py calls basicConfig at import time)
logging.root.setLevel(getattr(logging, os.environ.get('WHISPERLIVE_LOG_LEVEL', 'INFO'), logging.INFO))
server = TranscriptionServer()
server.run(
    '0.0.0.0',
    port=int(os.environ['WHISPERLIVE_PORT']),
    backend='faster_whisper',
    faster_whisper_custom_model_path=os.environ.get('_HF_REPO', 'Systran/faster-whisper-base'),
    max_clients=int(os.environ['WHISPERLIVE_MAX_CLIENTS']),
    max_connection_time=int(os.environ['WHISPERLIVE_MAX_CONNECTION_TIME']),
    cache_path=os.environ.get('HF_HOME', '/var/lib/whisper-live'),
    rest_port=int(os.environ['WHISPERLIVE_REST_PORT']),
    enable_rest=True,
    api_key=os.environ.get('WHISPERLIVE_API_KEY') or None,
)
" &
SERVER_PID=$!

# Wait for both the REST API port and the WebSocket port to accept TCP connections.
# The REST API (uvicorn) starts in a daemon thread before the WebSocket server loop
# begins; polling the REST port is the earliest reliable readiness signal.
# Allow up to 300 seconds — model download on first client connection can take several minutes.
wait_for_server() {
  local i=0
  while [ "$i" -lt 300 ]; do
    if ! kill -0 "$SERVER_PID" 2>/dev/null; then
      return 1
    fi
    # Use curl to probe the REST API docs endpoint (FastAPI always serves /docs)
    if [ -n "$WHISPERLIVE_API_KEY" ]; then
      if curl -sf --max-time 2 -H "Authorization: Bearer ${WHISPERLIVE_API_KEY}" \
          "http://127.0.0.1:${WHISPERLIVE_REST_PORT}/docs" >/dev/null 2>&1; then
        return 0
      fi
    elif curl -sf --max-time 2 "http://127.0.0.1:${WHISPERLIVE_REST_PORT}/docs" >/dev/null 2>&1; then
      return 0
    fi
    sleep 1
    i=$((i + 1))
  done
  return 1
}

if ! wait_for_server; then
  if ! kill -0 "$SERVER_PID" 2>/dev/null; then
    echo "Error: ScribeCrate Live server failed to start. Check the container logs for details." >&2
  else
    echo "Error: ScribeCrate Live server did not become ready within 300 seconds." >&2
    kill "$SERVER_PID" 2>/dev/null
  fi
  exit 1
fi

report_usage_counts

echo
echo "==========================================================="
echo " ScribeCrate Live real-time transcription server is ready"
echo "==========================================================="
echo " Model:          $WHISPERLIVE_MODEL"
echo " WebSocket:      ws://${server_addr}:${WHISPERLIVE_PORT}"
echo " REST API:       http://${server_addr}:${WHISPERLIVE_REST_PORT}"
echo "==========================================================="
echo
echo "Connect a client (WebSocket streaming):"
if [ -n "$WHISPERLIVE_API_KEY" ]; then
  echo "  ws://${server_addr}:${WHISPERLIVE_PORT}?token=<api-key>"
else
  echo "  ws://${server_addr}:${WHISPERLIVE_PORT}"
fi
echo
echo "Transcribe a file (REST API):"
echo "  curl http://${server_addr}:${WHISPERLIVE_REST_PORT}/v1/audio/transcriptions \\"
if [ -n "$WHISPERLIVE_API_KEY" ]; then
  echo "    -H \"Authorization: Bearer <api-key>\" \\"
fi
echo "    -F file=@audio.mp3 -F model=whisper-1"
echo
if [ -n "$WHISPERLIVE_API_KEY" ]; then
  echo "API key authentication is enabled."
  echo "Replace <api-key> with the key from: docker exec <container> whisper_live_manage --getkey"
  echo
fi
echo "Interactive API docs: http://${server_addr}:${WHISPERLIVE_REST_PORT}/docs"
echo "Docs, OpenAPI schema, and health checks are public."
if [ -n "$WHISPERLIVE_API_KEY" ]; then
  echo "Transcription requests require the Authorization: Bearer <api-key> header."
fi
echo
echo "To set up HTTPS, see: Using a reverse proxy"
echo "  https://github.com/hwdsl2/scribecrate-live#using-a-reverse-proxy"
echo
echo "Setup complete."
echo

# Wait for the server process to exit
wait "$SERVER_PID"
