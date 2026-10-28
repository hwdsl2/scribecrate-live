[English](README.md) | [简体中文](docs/README-zh.md) | [繁體中文](docs/README-zh-Hant.md) | [Русский](docs/README-ru.md)

# ScribeCrate Live

**Open-source, self-hosted real-time transcription server.**

[![Build Status](https://github.com/hwdsl2/scribecrate-live/actions/workflows/main.yml/badge.svg)](https://github.com/hwdsl2/scribecrate-live/actions/workflows/main.yml) &nbsp;[![Docker Pulls](https://raw.githubusercontent.com/hwdsl2/badges/main/img/docker-pulls-whisper-live-server.svg)](https://hub.docker.com/r/hwdsl2/whisper-live-server) &nbsp;[![License: MIT](docs/images/license.svg)](https://opensource.org/licenses/MIT) &nbsp;[![Open In Colab](https://colab.research.google.com/assets/colab-badge.svg)](https://selfhostedaistack.com/scribecrate-live-notebook)

ScribeCrate Live is a self-hosted real-time speech-to-text server powered by [WhisperLive](https://github.com/collabora/WhisperLive) and [faster-whisper](https://github.com/SYSTRAN/faster-whisper). It provides WebSocket transcription and speech-to-English translation for live microphone audio and audio streams, plus an OpenAI-compatible REST API for audio-file transcription. Deploy with Docker on CPU or an NVIDIA GPU. The image is based on Debian (python:3.12-slim).

> Previously known as `docker-whisper-live`, maintained by [hwdsl2](https://github.com/hwdsl2). The Docker image name remains `hwdsl2/whisper-live-server`.

**Features:**

- **Real-time WebSocket transcription:** transcribe live microphone audio or audio streams with progressive segment updates.
- **Speech-to-English translation:** translate speech into English over WebSocket with a suitable multilingual Whisper model.
- **OpenAI-compatible API:** `POST /v1/audio/transcriptions` for uploaded-file transcription from compatible OpenAI SDKs and apps.
- **Private, local processing:** audio stays on your server and is not sent to third parties.
- **Voice activity detection (VAD):** automatically skips silence for faster, cleaner transcription.
- **Whisper models:** supports all Whisper models, including `tiny`, `base`, `small`, `medium`, `large-v3`, `large-v3-turbo` and more.
- **CPU and GPU support:** run on CPU or use the `:cuda` image for NVIDIA GPU acceleration.
- **Offline operation:** run without internet access using pre-cached models (`WHISPERLIVE_LOCAL_ONLY`).
- **Automated builds:** images are automatically built and published through [GitHub Actions](https://github.com/hwdsl2/scribecrate-live/actions).

Also available as part of the [Self-Hosted AI Stack](https://github.com/hwdsl2/self-hosted-ai-stack), which deploys a complete self-hosted AI stack with a single command.

> 📘 [The Self-Hosted AI Builder’s Guide](https://books2read.com/aiguide?store=amazon) is a practical guide to building, securing, and operating your own private AI stack.

**Also available:**

- Try it online: [Open in Colab](https://selfhostedaistack.com/scribecrate-live-notebook) — no Docker or local installation required
- Related AI services: [ScribeCrate](https://github.com/hwdsl2/scribecrate), [SpeakCrate](https://github.com/hwdsl2/speakcrate), [EmbedCrate](https://github.com/hwdsl2/embedcrate), [GatewayCrate](https://github.com/hwdsl2/gatewaycrate), [InferCrate](https://github.com/hwdsl2/infercrate), [ParseCrate](https://github.com/hwdsl2/parsecrate), [UplinkCrate](https://github.com/hwdsl2/uplinkcrate)

## Quick start

Use this command to set up a ScribeCrate Live server:

```bash
docker run \
    --name whisper-live \
    --restart=always \
    -v whisper-live-data:/var/lib/whisper-live \
    -p 9090:9090 \
    -p 8000:8000 \
    -d hwdsl2/whisper-live-server
```

<details>
<summary><strong>GPU quick start (NVIDIA CUDA)</strong></summary>

If you have an NVIDIA GPU, use the `:cuda` image for hardware-accelerated inference:

```bash
docker run \
    --name whisper-live \
    --restart=always \
    --gpus=all \
    -v whisper-live-data:/var/lib/whisper-live \
    -p 9090:9090 \
    -p 8000:8000 \
    -d hwdsl2/whisper-live-server:cuda
```

**Requirements:** NVIDIA GPU, [NVIDIA driver](https://www.nvidia.com/en-us/drivers/) 575.57.08+ (Linux) or 576.57+ (Windows), and the [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html) installed on the host. The `:cuda` image is `linux/amd64` only.

</details>

> [!NOTE]
> For internet-facing deployments, use a [reverse proxy](#using-a-reverse-proxy) to add HTTPS. Also replace `-p 9090:9090 -p 8000:8000` with `-p 127.0.0.1:9090:9090 -p 127.0.0.1:8000:8000` in the `docker run` command above, to prevent direct access to the unencrypted ports.

The Whisper `base` model (~145 MB) is downloaded and cached on first client connection. Check the logs to confirm the server is ready:

```bash
docker logs whisper-live
```

Once you see "ScribeCrate Live real-time transcription server is ready":

Fresh persistent installations enable API-key authentication automatically. Retrieve the key:

```bash
scribe_live_api_key="$(docker exec whisper-live whisper_live_manage --getkey)"
```

**Connect a real-time WebSocket client:**

```
ws://your_server_ip:9090/?token=YOUR_API_KEY
```

**Or transcribe a file via the REST API:**

```bash
curl http://your_server_ip:8000/v1/audio/transcriptions \
    -H "Authorization: Bearer $scribe_live_api_key" \
    -F file=@audio.mp3 \
    -F model=whisper-1
```

**Response:**
```json
{"text": "Your transcribed text appears here."}
```

**Tip:** Need a sample audio file to test the REST API? Download this English speech sample (WAV, MIT License) from the [Azure Samples](https://github.com/Azure-Samples/cognitive-services-speech-sdk) repository:

```bash
curl -L -o sample_speech.wav \
    "https://github.com/Azure-Samples/cognitive-services-speech-sdk/raw/master/sampledata/audiofiles/katiesteve.wav"

curl http://your_server_ip:8000/v1/audio/transcriptions \
    -H "Authorization: Bearer $scribe_live_api_key" \
    -F file=@sample_speech.wav \
    -F model=whisper-1
```

## ScribeCrate vs. ScribeCrate Live

| | [ScribeCrate](https://github.com/hwdsl2/scribecrate) | **ScribeCrate Live** |
|---|---|---|
| **Use case** | Transcribe complete audio files | Live microphone / real-time audio streaming |
| **Protocol** | HTTP REST | WebSocket (streaming) + HTTP REST |
| **Speech-to-English translation** | File REST API: `/v1/audio/translations` | WebSocket: `task: "translate"`; REST supports file transcription |
| **Latency** | JSON after processing; segments via SSE | Progressive segment updates |
| **Best for** | Meeting recordings, uploaded audio | Browser capture, RTSP streams, live captions |
| **Image size** | ~190 MB (~3.1 GB for `:cuda`) | ~750 MB (~4.5 GB for `:cuda`) |

## Community

- 📬 [Get project updates and free deployment guides](https://selfhostedstack.beehiiv.com/subscribe?utm_campaign=ai) (1–2 emails/month)
- 💬 Join the [r/selfhostedstack](https://www.reddit.com/r/selfhostedstack/) community for discussions and showcases
- ⭐ Star the repository if you find it useful — it helps others discover it

<details>
<summary>Self-hosted VPN & networking projects</summary>

- [Setup IPsec VPN](https://github.com/hwdsl2/setup-ipsec-vpn)
- [IPsec VPN on Docker](https://github.com/hwdsl2/docker-ipsec-vpn-server)
- [WireGuard](https://github.com/hwdsl2/docker-wireguard)
- [OpenVPN](https://github.com/hwdsl2/docker-openvpn)
- [Headscale](https://github.com/hwdsl2/docker-headscale)

</details>

## Requirements

- A Linux server (local or cloud) with Docker installed
- Supported architectures: `amd64` (x86_64), `arm64` (e.g. Raspberry Pi 4/5, AWS Graviton)
- Minimum RAM: ~700 MB free for the default `base` model (see [model table](#switching-models))
- Internet access for the initial model download (the model is cached locally afterwards). Not required if using `WHISPERLIVE_LOCAL_ONLY=true` with pre-cached models.

**For GPU acceleration (`:cuda` image):**

- NVIDIA GPU with CUDA support (Compute Capability 6.0+)
- [NVIDIA driver](https://www.nvidia.com/en-us/drivers/) 575.57.08+ (Linux) or 576.57+ (Windows) installed on the host
- [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html) installed
- The `:cuda` image supports `linux/amd64` only

For internet-facing deployments, see [Using a reverse proxy](#using-a-reverse-proxy) to add HTTPS.

## Download

Get the trusted build from the [Docker Hub registry](https://hub.docker.com/r/hwdsl2/whisper-live-server/):

```bash
docker pull hwdsl2/whisper-live-server
```

For NVIDIA GPU acceleration, pull the `:cuda` tag instead:

```bash
docker pull hwdsl2/whisper-live-server:cuda
```

Alternatively, you may download from [Quay.io](https://quay.io/repository/hwdsl2/whisper-live-server):

```bash
docker pull quay.io/hwdsl2/whisper-live-server
docker image tag quay.io/hwdsl2/whisper-live-server hwdsl2/whisper-live-server
```

Supported platforms: `linux/amd64` and `linux/arm64`. The `:cuda` tag supports `linux/amd64` only.

## Environment variables

All variables are optional. Fresh installs with a mounted `/var/lib/whisper-live` volume auto-generate an API key. Existing installs without a key remain open for backward compatibility.

This Docker image uses the following variables, that can be declared in an `env` file (see [example](whisper-live.env.example)):

| Variable | Description | Default |
|---|---|---|
| `WHISPERLIVE_MODEL` | Whisper model for WebSocket transcription/translation and the REST default. See [model table](#switching-models) for options. | `base` |
| `WHISPERLIVE_PORT` | WebSocket port for real-time streaming clients (1–65535). | `9090` |
| `WHISPERLIVE_REST_PORT` | HTTP port for the OpenAI-compatible REST API (1–65535). | `8000` |
| `WHISPERLIVE_MAX_CLIENTS` | Maximum number of simultaneous WebSocket client connections. | `4` |
| `WHISPERLIVE_MAX_CONNECTION_TIME` | Maximum WebSocket connection duration in seconds. Clients exceeding this are disconnected. | `600` |
| `WHISPERLIVE_THREADS` | CPU threads for inference. Set to the number of physical cores for best latency. | `2` |
| `WHISPERLIVE_LOG_LEVEL` | Log level: `DEBUG`, `INFO`, `WARNING`, `ERROR`, `CRITICAL`. | `INFO` |
| `WHISPERLIVE_API_KEY` | Optional API key. Fresh persistent installs auto-generate one. REST transcription requests must include `Authorization: Bearer <key>`; WebSocket clients can use `?token=<key>`. Set explicitly empty to disable authentication. | Auto-generated for fresh persistent installs |
| `WHISPERLIVE_LOCAL_ONLY` | When set to any non-empty value (e.g. `true`), disables all HuggingFace model downloads. For offline or air-gapped deployments with pre-cached models. | *(not set)* |
| `WHISPERLIVE_DISABLE_USAGE_COUNTS` | Set to `1` to disable anonymous aggregate usage counts. | *(not set)* |

WebSocket clients set the source `language` (`null` for detection) and `use_vad` (`true` to enable VAD, `false` to disable it) in the handshake. REST clients set the request's `language` or omit it for detection. `WHISPERLIVE_LANGUAGE` and `WHISPERLIVE_USE_VAD` only affect startup-log values, not inference settings.

**Note:** In your `env` file, you may enclose values in single quotes, e.g. `VAR='value'`. Do not add spaces around `=`. If you change `WHISPERLIVE_PORT` or `WHISPERLIVE_REST_PORT`, update the `-p` flags in the `docker run` command accordingly.

Example using an `env` file:

```bash
cp whisper-live.env.example whisper-live.env
# Edit whisper-live.env with your settings, then:
docker run \
    --name whisper-live \
    --restart=always \
    -v whisper-live-data:/var/lib/whisper-live \
    -v ./whisper-live.env:/whisper-live.env:ro \
    -p 9090:9090 \
    -p 8000:8000 \
    -d hwdsl2/whisper-live-server
```

The env file is bind-mounted into the container, so changes are picked up on every restart without recreating the container.

<details>
<summary>Alternatively, pass it with <code>--env-file</code></summary>

```bash
docker run \
    --name whisper-live \
    --restart=always \
    -v whisper-live-data:/var/lib/whisper-live \
    -p 9090:9090 \
    -p 8000:8000 \
    --env-file=whisper-live.env \
    -d hwdsl2/whisper-live-server
```

</details>

## Using docker-compose

```bash
cp whisper-live.env.example whisper-live.env
# Edit whisper-live.env as needed, then:
docker compose up -d
docker logs whisper-live
```

Example `docker-compose.yml` (already included):

```yaml
services:
  whisper-live:
    image: hwdsl2/whisper-live-server
    container_name: whisper-live
    restart: always
    ports:
      - "9090:9090/tcp"  # WebSocket — for a host-based reverse proxy, change to "127.0.0.1:9090:9090/tcp"
      - "8000:8000/tcp"  # REST API  — for a host-based reverse proxy, change to "127.0.0.1:8000:8000/tcp"
    volumes:
      - whisper-live-data:/var/lib/whisper-live
      - ./whisper-live.env:/whisper-live.env:ro

volumes:
  whisper-live-data:
    name: whisper-live-data
```

> [!NOTE]
> For internet-facing deployments, use a [reverse proxy](#using-a-reverse-proxy) to add HTTPS. Also change `"9090:9090/tcp"` and `"8000:8000/tcp"` to their `127.0.0.1:` equivalents in `docker-compose.yml`.

<details>
<summary><strong>Using docker-compose with GPU (NVIDIA CUDA)</strong></summary>

A separate `docker-compose.cuda.yml` is provided for GPU deployments:

```bash
cp whisper-live.env.example whisper-live.env
# Edit whisper-live.env as needed, then:
docker compose -f docker-compose.cuda.yml up -d
docker logs whisper-live
```

Example `docker-compose.cuda.yml` (already included):

```yaml
services:
  whisper-live:
    image: hwdsl2/whisper-live-server:cuda
    container_name: whisper-live
    restart: always
    ports:
      - "9090:9090/tcp"  # WebSocket — for a host-based reverse proxy, change to "127.0.0.1:9090:9090/tcp"
      - "8000:8000/tcp"  # REST API  — for a host-based reverse proxy, change to "127.0.0.1:8000:8000/tcp"
    volumes:
      - whisper-live-data:/var/lib/whisper-live
      - ./whisper-live.env:/whisper-live.env:ro
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: 1
              capabilities: [gpu]

volumes:
  whisper-live-data:
    name: whisper-live-data
```

</details>

## WebSocket streaming

The WebSocket endpoint at port `9090` supports real-time transcription and speech-to-English translation of live audio streams. Clients send raw PCM audio chunks and receive text segments as they are decoded.

### Protocol

On connection, send a JSON configuration message first:

```json
{
  "uid": "unique-client-id",
  "language": "en",
  "model": "base",
  "task": "transcribe",
  "audio_format": "float32",
  "use_vad": true
}
```

Wait for the server's `SERVER_READY` message before sending audio. Stream raw **mono float32 PCM at 16 kHz**, with sample values normalized to [-1, 1], as binary WebSocket frames. Do not send WAV headers or compressed audio in these frames. The server returns JSON text-segment events:

```json
{"uid": "unique-client-id", "segments": [{"text": "Hello, how are you?", "start": 0.0, "end": 2.4, "completed": true}]}
```

### Python client example

The upstream `whisper-live` 0.9.0 client does not expose an API-key argument. This adapter sends the Bearer header during the WebSocket handshake and retains file and microphone transcription. Install the matching client version and export your server key before running the Python example:

```bash
pip install whisper-live==0.9.0
export WHISPERLIVE_API_KEY="$(docker exec whisper-live whisper_live_manage --getkey)"
```

If API key authentication is disabled, set `WHISPERLIVE_API_KEY` to an empty string.

```python
import os
import websocket
from whisper_live.client import Client, TranscriptionTeeClient


class AuthenticatedClient(Client):
    def _create_websocket(self):
        key = os.environ["WHISPERLIVE_API_KEY"]
        headers = {"Authorization": f"Bearer {key}"} if key else {}
        self.client_socket = websocket.WebSocketApp(
            self.socket_url,
            header=headers,
            on_open=self.on_open,
            on_message=self.on_message,
            on_error=self.on_error,
            on_close=self.on_close,
        )


connection = AuthenticatedClient(
    "your_server_ip",
    9090,
    lang="en",
    translate=False,
    model="base",
    use_vad=True,
)
client = TranscriptionTeeClient([connection])

# Transcribe from a file
client("audio.mp3")

# Or transcribe from microphone
# client()
```

### Translate speech into English

Reuse the `AuthenticatedClient` adapter and exported API key from the Python example above. Set `translate=True` to request Whisper's speech-to-English task:

```python
connection = AuthenticatedClient(
    "your_server_ip",
    9090,
    lang="es",
    translate=True,
    model="base",
    use_vad=True,
)
client = TranscriptionTeeClient([connection])

# Spanish source audio; output text is English
client("spanish.wav")
```

Here `lang="es"` selects the **source** language, not the output language. Use `lang=None` for automatic source-language detection; raw WebSocket clients use `"language": null`. For raw clients, set `"task": "translate"` in the same authenticated handshake shown above. Output is English; this task does not select an arbitrary target language.

The example works with the server's default multilingual `base` model. WebSocket inference uses the model configured by **server-side `WHISPERLIVE_MODEL`**; the client's `model` field does not override it in this image. To use another model, change the server setting and [restart or recreate the container as appropriate](#environment-variables). Choose a multilingual non-turbo model such as `base`, `small`, `medium`, or `large-v3`. English-only `.en` models do not support this task, and `large-v3-turbo` / `turbo` are not trained for reliable translation.

Translation is available through WebSocket. This image's REST API provides **file transcription** at `/v1/audio/transcriptions`; it does not expose `/v1/audio/translations`.

### Browser client example

```javascript
const apiKey = "YOUR_API_KEY";
const ws = new WebSocket(`ws://your_server_ip:9090/?token=${encodeURIComponent(apiKey)}`);

let serverReady = false;

ws.onopen = () => {
  // Send configuration
  ws.send(JSON.stringify({
    uid: "browser-client-1",
    language: "en",
    model: "base",
    task: "transcribe",
    audio_format: "float32",
    use_vad: true,
  }));
};

ws.onmessage = (event) => {
  const data = JSON.parse(event.data);
  if (data.message === "SERVER_READY") serverReady = true;
  if (data.segments) {
    data.segments.forEach(seg => console.log(seg.text));
  }
};

// Samples must already be mono, normalized to [-1, 1], and resampled to 16 kHz.
function sendAudio(samples) {
  if (!serverReady || ws.readyState !== WebSocket.OPEN) return;
  const chunk = new Float32Array(samples);
  ws.send(chunk.buffer);
}
```

## REST API reference

Translation is available through WebSocket. This image's REST API provides **file transcription** at `/v1/audio/transcriptions`; it does not expose `/v1/audio/translations`.

The REST API at port `8000` is compatible with [OpenAI's audio transcription endpoint](https://developers.openai.com/api/reference/resources/audio/subresources/transcriptions/methods/create). For clients using the OpenAI SDK, configure the base URL and your server's API key:

Fresh persistent installations require an API key. Retrieve it for the following examples:

```bash
scribe_live_api_key="$(docker exec whisper-live whisper_live_manage --getkey)"

export OPENAI_BASE_URL="http://your_server_ip:8000/v1"
export OPENAI_API_KEY="$scribe_live_api_key"
```

If API key authentication is disabled, omit the `Authorization` header in curl examples. OpenAI SDK clients still require a nonempty key; set `OPENAI_API_KEY=unused`.

### Transcribe audio

```
POST /v1/audio/transcriptions
Content-Type: multipart/form-data
```

**Parameters:**

| Parameter | Type | Required | Description |
|---|---|---|---|
| `file` | file | ✅ | Audio file. Supported formats: `mp3`, `mp4`, `m4a`, `wav`, `webm`, `ogg`, `flac` and all other formats supported by ffmpeg. |
| `model` | string | — | Omit or pass `whisper-1` to use `WHISPERLIVE_MODEL`. Pass a supported Whisper size (e.g. `small`, `medium`, `large-v3`), existing local model path, or Hugging Face repository ID to select another model for this request. Other names fall back to `WHISPERLIVE_MODEL`; an unavailable model path or repository can fail to load. |
| `language` | string | — | BCP-47 language code (e.g. `en`, `fr`, `zh`). If omitted, language is autodetected. |

**Example:**

```bash
curl http://your_server_ip:8000/v1/audio/transcriptions \
    -H "Authorization: Bearer $scribe_live_api_key" \
    -F file=@meeting.m4a \
    -F model=whisper-1 \
    -F language=en
```

**Response:**
```json
{"text": "Your transcribed text appears here."}
```

### Interactive API docs

An interactive Swagger UI is available at:

```
http://your_server_ip:8000/docs
```

WhisperLive 0.10.0 serves `/docs`, `/redoc`, `/openapi.json`, and `/health` without API-key authentication. When authentication is enabled, transcription requests still require `Authorization: Bearer <key>`, including requests sent from Swagger UI. To use Swagger UI for transcription, arrange for that header to be sent on API requests; the token query parameter only authenticates WebSocket connections.

## Persistent data

All server data is stored in the Docker volume (`/var/lib/whisper-live` inside the container):

```
/var/lib/whisper-live/
├── models--Systran--faster-whisper-*/   # Cached Whisper model files (downloaded from HuggingFace)
├── .ws_port              # Active WebSocket port (used by whisper_live_manage)
├── .rest_port            # Active REST API port (used by whisper_live_manage)
├── .model                # Active model name (used by whisper_live_manage)
└── .server_addr          # Cached server IP (used by whisper_live_manage)
```

Back up the Docker volume to preserve downloaded models. Models are large (145 MB – 3 GB) and can take several minutes to download on first client connection; preserving the volume avoids re-downloading on container recreation.

**Tip:** The `/var/lib/whisper-live` volume uses the same HuggingFace cache layout as ScribeCrate's `/var/lib/whisper` volume. If you have already downloaded a model with ScribeCrate, you can bind-mount the same volume directory to avoid re-downloading.

## Managing the server

Use `whisper_live_manage` inside the running container to inspect and manage the server.

**Show server info:**

```bash
docker exec whisper-live whisper_live_manage --showinfo
```

**List available models:**

```bash
docker exec whisper-live whisper_live_manage --listmodels
```

**Pre-download a model:**

```bash
docker exec whisper-live whisper_live_manage --downloadmodel large-v3-turbo
```

## Switching models

To change the active model:

1. *(Optional but recommended)* Pre-download the new model while the server is running:
   ```bash
   docker exec whisper-live whisper_live_manage --downloadmodel large-v3-turbo
   ```

2. Update `WHISPERLIVE_MODEL` in your `whisper-live.env` file (or add `-e WHISPERLIVE_MODEL=large-v3-turbo` to your `docker run` command).

3. If using a bind-mounted env file, restart the container. With `--env-file` or `-e`, recreate it to apply the new setting:
   ```bash
   docker restart whisper-live
   ```

**Available models:**

| Model | Disk | RAM (approx) | Notes |
|---|---|---|---|
| `tiny` | ~75 MB | ~250 MB | Fastest; lower accuracy |
| `tiny.en` | ~75 MB | ~250 MB | English-only |
| `base` | ~145 MB | ~700 MB | Good balance — **default** |
| `base.en` | ~145 MB | ~700 MB | English-only |
| `small` | ~465 MB | ~1.5 GB | Better accuracy |
| `small.en` | ~465 MB | ~1.5 GB | English-only |
| `medium` | ~1.5 GB | ~5 GB | High accuracy |
| `medium.en` | ~1.5 GB | ~5 GB | English-only |
| `large-v1` | ~3 GB | ~10 GB | Older large model |
| `large-v2` | ~3 GB | ~10 GB | Very high accuracy |
| `large-v3` | ~3 GB | ~10 GB | Best accuracy |
| `large-v3-turbo` | ~1.6 GB | ~6 GB | Fast + high accuracy ⭐; transcription only |
| `turbo` | ~1.6 GB | ~6 GB | Alias for `large-v3-turbo`; transcription only |

> **Tip:** For transcription, `large-v3-turbo` is a faster alternative to `large-v3` on hardware with sufficient resources. For speech-to-English translation, choose a multilingual non-turbo model such as `base`, `small`, `medium`, or `large-v3`.

RAM values are rough planning estimates, not measured requirements or GPU VRAM figures. The CPU backend uses INT8; the CUDA backend uses FP16 on GPUs with Compute Capability 7.0+ and FP32 on older supported GPUs. Actual RAM/VRAM use varies with model, audio length, and concurrent clients. Models are cached in the `/var/lib/whisper-live` Docker volume and only downloaded once.

## Securing your server

If your ScribeCrate Live server is reachable from the public internet — even briefly — apply at minimum these protections. ScribeCrate Live is CPU/GPU-intensive, so an unprotected endpoint can be abused to burn your compute resources.

**1. Use an API key.** Fresh installs with a mounted `/var/lib/whisper-live` volume auto-generate an API key. Display it with `docker exec whisper-live whisper_live_manage --showkey`, or use `docker exec whisper-live whisper_live_manage --getkey` in scripts. Existing installs without a key remain open for backward compatibility; set `WHISPERLIVE_API_KEY` in your `env` file to enable authentication manually. REST transcription clients must send `Authorization: Bearer <key>`; WebSocket clients can send the same header or add `?token=<key>` to the URL.

**2. Bind to localhost when fronted by a reverse proxy.** Replace `-p 9090:9090 -p 8000:8000` with `-p 127.0.0.1:9090:9090 -p 127.0.0.1:8000:8000` (or change both port mappings to their `127.0.0.1:` equivalents in `docker-compose.yml`) so the unencrypted ports are not reachable directly from outside the host.

**3. Limit upload size at the proxy.** Audio files can be large; configure your reverse proxy to reject oversized uploads (e.g. nginx `client_max_body_size 100M;`). This bounds the disk and memory footprint of a single request.

**4. Mind the log level.** `WHISPERLIVE_LOG_LEVEL=DEBUG` may write transcript text to logs. Keep it at `INFO` or higher on shared systems.

**5. Restrict WebSocket origins at the proxy.** WebSocket connections from untrusted browser origins can be blocked at the reverse proxy. For nginx, check `$http_origin` before upgrading the connection; for Caddy, use the `header` directive to validate the `Origin` header.

**6. Consider rate limiting.** Place a rate-limit (e.g. nginx `limit_req_zone`, Caddy `rate_limit`) in front of the server to cap concurrent transcriptions per client IP.

## Using a reverse proxy

For internet-facing deployments, place a reverse proxy in front of the server to handle HTTPS and WSS (secure WebSocket) termination.

Use one of the following addresses to reach the container from your reverse proxy:

- **`whisper-live:9090`** / **`whisper-live:8000`** — if your reverse proxy runs as a container in the **same Docker network**.
- **`127.0.0.1:9090`** / **`127.0.0.1:8000`** — if your reverse proxy runs **on the host** and the ports are published.

**Example with [Caddy](https://caddyserver.com/docs/) ([Docker image](https://hub.docker.com/_/caddy))** (automatic TLS, WebSocket proxying in the same Docker network):

`Caddyfile`:
```
whisper-live.example.com {
  # WebSocket streaming (wss://)
  handle /ws* {
    reverse_proxy whisper-live:9090
  }
  # REST API (https://)
  reverse_proxy whisper-live:8000
}
```

**Example with nginx** (reverse proxy on the host):

```nginx
server {
    listen 443 ssl;
    server_name whisper-live.example.com;

    ssl_certificate     /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;

    # REST API
    location /v1/ {
        proxy_pass         http://127.0.0.1:8000;
        proxy_set_header   Host $host;
        proxy_set_header   X-Real-IP $remote_addr;
        proxy_set_header   X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header   X-Forwarded-Proto $scheme;
        proxy_read_timeout 300s;
    }

    # WebSocket streaming
    location / {
        proxy_pass         http://127.0.0.1:9090;
        proxy_http_version 1.1;
        proxy_set_header   Upgrade $http_upgrade;
        proxy_set_header   Connection "upgrade";
        proxy_set_header   Host $host;
        proxy_read_timeout 600s;
    }
}
```

> [!IMPORTANT]
> WebSocket proxying requires `proxy_http_version 1.1` and the `Upgrade`/`Connection` headers. Without these, real-time streaming will not work through nginx.

<details>
<summary><strong>Adding extra authentication at the proxy layer</strong></summary>

The server supports native API-key authentication via `WHISPERLIVE_API_KEY`. For internet-facing deployments, you can also add Bearer token or basic auth at the reverse proxy layer as defense in depth. Example with Caddy (`basicauth` protects the REST API):

```
whisper-live.example.com {
  handle /v1/* {
    basicauth {
      user $2a$14$<bcrypt-hash-of-password>
    }
    reverse_proxy whisper-live:8000
  }
  handle /ws* {
    reverse_proxy whisper-live:9090
  }
  reverse_proxy whisper-live:8000
}
```

Example with nginx (`auth_basic` on the REST API location):

```nginx
location /v1/ {
    auth_basic           "WhisperLive";
    auth_basic_user_file /etc/nginx/.htpasswd;
    proxy_pass           http://127.0.0.1:8000;
    proxy_set_header     Host $host;
    proxy_read_timeout   300s;
}
```

Non-browser WebSocket clients can authenticate with an `Authorization` header. Because the browser WebSocket API cannot set arbitrary headers, browser clients can use `?token=<key>`. For defense in depth, keep port `9090` bound to `127.0.0.1` behind the reverse proxy.

</details>

## Update Docker image

To update the Docker image and container, first [download](#download) the latest version:

```bash
docker pull hwdsl2/whisper-live-server
```

If the Docker image is already up to date, you should see:

```
Status: Image is up to date for hwdsl2/whisper-live-server:latest
```

Otherwise, it will download the latest version. Remove and re-create the container:

```bash
docker rm -f whisper-live
# Then re-run the docker run command from Quick start with the same volumes and ports.
```

Your downloaded models are preserved in the `whisper-live-data` volume.

## Using with other AI services

ScribeCrate Live can be used as the real-time speech-to-text service in a broader self-hosted AI setup.

For full and lightweight Docker Compose stacks, manual `docker run` examples, and voice/RAG/MCP pipeline examples with SpeakCrate, EmbedCrate, GatewayCrate, InferCrate, ParseCrate, and UplinkCrate, see [Self-Hosted AI Stack](https://github.com/hwdsl2/self-hosted-ai-stack).

## Usage counts

This image uses public GitHub release asset download counts for anonymous, aggregate usage counts. Counts are approximate and are not unique users or active installs. The image does not send a telemetry payload or use a private collector. It only attempts the best-effort count after the server starts successfully with a mounted `/var/lib/whisper-live` volume, and again when that persistent install first runs a different image build. To opt out, set `WHISPERLIVE_DISABLE_USAGE_COUNTS=1`.

## Technical details

- Base image: `python:3.12-slim` (Debian)
- Runtime: Python 3 (virtual environment at `/opt/venv`)
- STT engine: [WhisperLive](https://github.com/collabora/WhisperLive) + [faster-whisper](https://github.com/SYSTRAN/faster-whisper) with CTranslate2 (INT8 on CPU, FP16/FP32 on CUDA)
- VAD: [Silero VAD](https://github.com/snakers4/silero-vad) via PyTorch (CPU or CUDA, auto-detected)
- WebSocket server: Python `websockets` library
- REST API framework: [FastAPI](https://fastapi.tiangolo.com/) + [Uvicorn](https://www.uvicorn.org/)
- Data directory: `/var/lib/whisper-live` (Docker volume)
- Model storage: HuggingFace Hub format inside the volume — downloaded once, reused on restarts

## License

**Note:** The software components inside the pre-built image (such as WhisperLive, faster-whisper, PyTorch, and their dependencies) are under the respective licenses chosen by their respective copyright holders. As for any pre-built image usage, it is the image user's responsibility to ensure that any use of this image complies with any relevant licenses for all software contained within.

Copyright (C) 2026 Lin Song   
This work is licensed under the [MIT License](https://opensource.org/licenses/MIT).

**WhisperLive** is Copyright (C) Vineet Suryan, Collabora Ltd., and is distributed under the [MIT License](https://github.com/collabora/WhisperLive/blob/main/LICENSE).

**faster-whisper** is Copyright (C) SYSTRAN, and is distributed under the [MIT License](https://github.com/SYSTRAN/faster-whisper/blob/master/LICENSE).

This project is an independent Docker setup and is not affiliated with, endorsed by, or sponsored by OpenAI, Collabora, or SYSTRAN.
