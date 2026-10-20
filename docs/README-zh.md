[English](../README.md) | [简体中文](README-zh.md) | [繁體中文](README-zh-Hant.md) | [Русский](README-ru.md)

# ScribeCrate Live

**开源、自托管的实时转录服务器。**

[![构建状态](https://github.com/hwdsl2/scribecrate-live/actions/workflows/main.yml/badge.svg)](https://github.com/hwdsl2/scribecrate-live/actions/workflows/main.yml) &nbsp;[![Docker Pulls](https://raw.githubusercontent.com/hwdsl2/badges/main/img/docker-pulls-whisper-live-server.svg)](https://hub.docker.com/r/hwdsl2/whisper-live-server) &nbsp;[![License: MIT](images/license.svg)](https://opensource.org/licenses/MIT) &nbsp;[![Open In Colab](https://colab.research.google.com/assets/colab-badge.svg)](https://selfhostedaistack.com/scribecrate-live-notebook)

ScribeCrate Live 是一个自托管的实时语音转文字服务器，由 [WhisperLive](https://github.com/collabora/WhisperLive) 和 [faster-whisper](https://github.com/SYSTRAN/faster-whisper) 提供支持。它提供用于实时麦克风音频和音频流转录的 WebSocket 服务，以及用于音频文件转录的 OpenAI 兼容 REST API。可使用 Docker 在 CPU 或 NVIDIA GPU 上部署。镜像基于 Debian（python:3.12-slim）。

> 本项目原名为 `docker-whisper-live`，由 [hwdsl2](https://github.com/hwdsl2) 维护。Docker 镜像名称仍为 `hwdsl2/whisper-live-server`。

**功能特性：**

- **实时 WebSocket 转录：** 转录实时麦克风音频或音频流，并逐步返回分段结果
- **兼容 OpenAI 的 API：** 通过 `POST /v1/audio/transcriptions` 为兼容的 OpenAI SDK 和应用提供上传文件转录。
- **私密的本地处理：** 音频数据留在您的服务器上，不发送给第三方
- **语音活动检测 (VAD)：** 自动跳过静音段，实现更快、更干净的转录
- **Whisper 模型：** 支持所有 Whisper 模型，包括 `tiny`、`base`、`small`、`medium`、`large-v3`、`large-v3-turbo` 等
- **CPU 和 GPU 支持：** 可在 CPU 上运行，或使用 `:cuda` 镜像启用 NVIDIA GPU 加速。
- **离线运行：** 使用预先缓存的模型无需互联网访问 (`WHISPERLIVE_LOCAL_ONLY`)
- **自动构建：** 通过 [GitHub Actions](https://github.com/hwdsl2/scribecrate-live/actions) 自动构建和发布

也可作为 [Self-Hosted AI Stack](https://github.com/hwdsl2/self-hosted-ai-stack/blob/main/docs/README-zh.md) 的一部分使用，一条命令即可部署完整的自托管 AI 技术栈。

> 📘 [The Self-Hosted AI Builder’s Guide](https://books2read.com/aiguide?store=amazon) 是一本关于构建、保护和运维自己的私有 AI 技术栈的实用指南。

**另提供：**

- 在线试用：[在 Colab 中打开](https://selfhostedaistack.com/scribecrate-live-notebook)——无需 Docker 或本地安装
- 相关 AI 服务：[ScribeCrate](https://github.com/hwdsl2/scribecrate/blob/main/docs/README-zh.md)、[SpeakCrate](https://github.com/hwdsl2/speakcrate/blob/main/docs/README-zh.md)、[EmbedCrate](https://github.com/hwdsl2/embedcrate/blob/main/docs/README-zh.md)、[GatewayCrate](https://github.com/hwdsl2/gatewaycrate/blob/main/docs/README-zh.md)、[InferCrate](https://github.com/hwdsl2/infercrate/blob/main/docs/README-zh.md)、[ParseCrate](https://github.com/hwdsl2/parsecrate/blob/main/docs/README-zh.md)、[UplinkCrate](https://github.com/hwdsl2/uplinkcrate/blob/main/docs/README-zh.md)

## 快速开始

使用以下命令启动 ScribeCrate Live 服务器：

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
<summary><strong>GPU 快速开始（NVIDIA CUDA）</strong></summary>

如果您有 NVIDIA GPU，可使用 `:cuda` 镜像进行硬件加速推理：

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

**要求：** NVIDIA GPU、[NVIDIA 驱动](https://www.nvidia.com/en-us/drivers/) 575.57.08+（Linux）或 576.57+（Windows），以及主机上已安装 [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html)。`:cuda` 镜像仅支持 `linux/amd64`。

</details>

**重要：** 此镜像运行默认 `base` 模型需要至少 700 MB 可用内存。内存为 512 MB 或更少的系统不受支持。

> [!NOTE]
> 如需面向互联网的部署，请使用[反向代理](#使用反向代理)来添加 HTTPS。同时，请将上述 `docker run` 命令中的 `-p 9090:9090 -p 8000:8000` 替换为 `-p 127.0.0.1:9090:9090 -p 127.0.0.1:8000:8000`，以防止从外部直接访问未加密端口。

首次客户端连接时，Whisper `base` 模型（约 145 MB）将自动下载并缓存。查看日志确认服务器已就绪：

```bash
docker logs whisper-live
```

看到 "ScribeCrate Live real-time transcription server is ready" 后：

新的持久化安装会自动启用 API 密钥认证。获取密钥：

```bash
scribe_live_api_key="$(docker exec whisper-live whisper_live_manage --getkey)"
```

**连接实时 WebSocket 客户端：**

```
ws://您的服务器IP:9090/?token=您的API密钥
```

**或通过 REST API 转录文件：**

```bash
curl http://您的服务器IP:8000/v1/audio/transcriptions \
    -H "Authorization: Bearer $scribe_live_api_key" \
    -F file=@audio.mp3 \
    -F model=whisper-1
```

**响应：**
```json
{"text": "转录的文字内容显示在这里。"}
```

**提示：** 需要示例音频文件测试 REST API？可以使用来自 [Azure Samples](https://github.com/Azure-Samples/cognitive-services-speech-sdk) 仓库的英语语音示例（WAV 格式，MIT 许可证）：

```bash
curl -L -o sample_speech.wav \
    "https://github.com/Azure-Samples/cognitive-services-speech-sdk/raw/master/sampledata/audiofiles/katiesteve.wav"

curl http://您的服务器IP:8000/v1/audio/transcriptions \
    -H "Authorization: Bearer $scribe_live_api_key" \
    -F file=@sample_speech.wav \
    -F model=whisper-1
```

## ScribeCrate 与 ScribeCrate Live 的选择

| | [ScribeCrate](https://github.com/hwdsl2/scribecrate/blob/main/docs/README-zh.md) | **ScribeCrate Live** |
|---|---|---|
| **使用场景** | 转录完整音频文件 | 实时麦克风/音频流 |
| **协议** | HTTP REST | WebSocket（流式）+ HTTP REST |
| **延迟** | 处理完成后返回 JSON；SSE 逐段返回 | 逐步返回分段结果 |
| **适合** | 会议录音、上传的音频文件 | 浏览器采集、RTSP 流、实时字幕 |
| **镜像大小** | ~190 MB（`:cuda` 约 3.1 GB） | ~750 MB（`:cuda` 约 4.5 GB） |

## 社区

- 📬 [获取项目更新和免费部署指南](https://selfhostedstack.beehiiv.com/subscribe?utm_campaign=ai-zh)（每月 1–2 封邮件；指南为英文 PDF）
- 💬 加入 [r/selfhostedstack](https://www.reddit.com/r/selfhostedstack/) 社区，参与讨论和项目展示
- ⭐ 如果你觉得本项目有用，请为仓库加星——这有助于让更多人发现它。

<details>
<summary>自托管 VPN 和网络项目</summary>

- [Setup IPsec VPN](https://github.com/hwdsl2/setup-ipsec-vpn/blob/master/README-zh.md)
- [Docker 上的 IPsec VPN](https://github.com/hwdsl2/docker-ipsec-vpn-server/blob/master/README-zh.md)
- [WireGuard](https://github.com/hwdsl2/docker-wireguard/blob/main/docs/README-zh.md)
- [OpenVPN](https://github.com/hwdsl2/docker-openvpn/blob/main/docs/README-zh.md)
- [Headscale](https://github.com/hwdsl2/docker-headscale/blob/main/docs/README-zh.md)

</details>

## 系统要求

- 已安装 Docker 的 Linux 服务器（本地或云端）
- 支持的架构：`amd64`（x86_64）、`arm64`（例如 Raspberry Pi 4/5、AWS Graviton）
- 最低内存：默认 `base` 模型约需 700 MB 可用内存（请参阅[模型列表](#切换模型)）
- 首次启动需要访问互联网以下载模型（之后模型将缓存在本地）。使用预先缓存的模型并设置 `WHISPERLIVE_LOCAL_ONLY=true` 时不需要网络访问。

**GPU 加速（`:cuda` 镜像）要求：**

- 支持 CUDA 的 NVIDIA GPU（计算能力 6.0+）
- 主机已安装 [NVIDIA 驱动](https://www.nvidia.com/en-us/drivers/) 575.57.08+（Linux）或 576.57+（Windows）
- 已安装 [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html)
- `:cuda` 镜像仅支持 `linux/amd64`

如需面向公网部署，请参阅[使用反向代理](#使用反向代理)以启用 HTTPS。

## 下载

从 [Docker Hub](https://hub.docker.com/r/hwdsl2/whisper-live-server/) 获取可信构建：

```bash
docker pull hwdsl2/whisper-live-server
```

如需 NVIDIA GPU 加速，请拉取 `:cuda` 标签：

```bash
docker pull hwdsl2/whisper-live-server:cuda
```

也可从 [Quay.io](https://quay.io/repository/hwdsl2/whisper-live-server) 下载：

```bash
docker pull quay.io/hwdsl2/whisper-live-server
docker image tag quay.io/hwdsl2/whisper-live-server hwdsl2/whisper-live-server
```

支持平台：`linux/amd64` 和 `linux/arm64`。`:cuda` 标签仅支持 `linux/amd64`。

## 环境变量

所有变量均为可选。挂载 `/var/lib/whisper-live` 数据卷的新安装会自动生成 API 密钥。没有密钥的既有安装会保持开放以兼容旧行为。

此 Docker 镜像使用以下变量，可在 `env` 文件中声明（参见[示例](../whisper-live.env.example)）：

| 变量 | 说明 | 默认值 |
|---|---|---|
| `WHISPERLIVE_MODEL` | 使用的 Whisper 模型。请参阅[模型列表](#切换模型)。 | `base` |
| `WHISPERLIVE_LANGUAGE` | 默认转录语言。使用 BCP-47 语言代码（如 `zh`、`en`、`ja`）或 `auto` 自动检测。 | `auto` |
| `WHISPERLIVE_PORT` | 实时流式客户端的 WebSocket 端口（1–65535）。 | `9090` |
| `WHISPERLIVE_REST_PORT` | OpenAI 兼容 REST API 的 HTTP 端口（1–65535）。 | `8000` |
| `WHISPERLIVE_MAX_CLIENTS` | 最大同时 WebSocket 客户端连接数。 | `4` |
| `WHISPERLIVE_MAX_CONNECTION_TIME` | WebSocket 最大连接时长（秒）。超过此时长的客户端将被自动断开。 | `600` |
| `WHISPERLIVE_USE_VAD` | 启用语音活动检测。设为 `true` 时自动检测并跳过静音段。设为 `false` 持续处理所有音频。 | `true` |
| `WHISPERLIVE_THREADS` | 推理使用的 CPU 线程数。设为物理核心数可获得最佳延迟。 | `2` |
| `WHISPERLIVE_API_KEY` | 可选 API 密钥。新持久化安装会自动生成。REST 转录请求须包含 `Authorization: Bearer <key>`；WebSocket 客户端可使用 `?token=<key>`。显式设置为空可禁用认证。 | 新持久化安装自动生成 |
| `WHISPERLIVE_LOG_LEVEL` | 日志级别：`DEBUG`、`INFO`、`WARNING`、`ERROR`、`CRITICAL`。 | `INFO` |
| `WHISPERLIVE_LOCAL_ONLY` | 设为任意非空值（如 `true`）时，禁止所有 HuggingFace 模型下载。适用于预先缓存模型的离线或隔离网络部署。 | *（未设置）* |
| `WHISPERLIVE_DISABLE_USAGE_COUNTS` | 设为 `1` 可禁用匿名聚合使用计数。 | *（未设置）* |

**注：** 在 `env` 文件中，值可用单引号括起，例如 `VAR='value'`。`=` 两侧不要有空格。如更改 `WHISPERLIVE_PORT` 或 `WHISPERLIVE_REST_PORT`，请相应更新 `docker run` 命令中的 `-p` 参数。

使用 `env` 文件的示例：

```bash
cp whisper-live.env.example whisper-live.env
# 编辑 whisper-live.env 配置您的设置，然后：
docker run \
    --name whisper-live \
    --restart=always \
    -v whisper-live-data:/var/lib/whisper-live \
    -v ./whisper-live.env:/whisper-live.env:ro \
    -p 9090:9090 \
    -p 8000:8000 \
    -d hwdsl2/whisper-live-server
```

`env` 文件以绑定挂载方式传入容器，每次重启时自动生效，无需重建容器。

<details>
<summary>也可通过 <code>--env-file</code> 传入</summary>

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

## 使用 docker-compose

```bash
cp whisper-live.env.example whisper-live.env
# 按需编辑 whisper-live.env，然后：
docker compose up -d
docker logs whisper-live
```

示例 `docker-compose.yml`（已包含在项目中）：

```yaml
services:
  whisper-live:
    image: hwdsl2/whisper-live-server
    container_name: whisper-live
    restart: always
    ports:
      - "9090:9090/tcp"  # WebSocket — 如使用主机反向代理，改为 "127.0.0.1:9090:9090/tcp"
      - "8000:8000/tcp"  # REST API  — 如使用主机反向代理，改为 "127.0.0.1:8000:8000/tcp"
    volumes:
      - whisper-live-data:/var/lib/whisper-live
      - ./whisper-live.env:/whisper-live.env:ro

volumes:
  whisper-live-data:
    name: whisper-live-data
```

> [!NOTE]
> 如需面向公网部署，请使用[反向代理](#使用反向代理)启用 HTTPS。同时，请将 `docker-compose.yml` 中的端口改为其 `127.0.0.1:` 形式。

<details>
<summary><strong>使用 docker-compose 部署 GPU（NVIDIA CUDA）</strong></summary>

项目提供了单独的 `docker-compose.cuda.yml` 用于 GPU 部署：

```bash
cp whisper-live.env.example whisper-live.env
# 按需编辑 whisper-live.env，然后：
docker compose -f docker-compose.cuda.yml up -d
docker logs whisper-live
```

示例 `docker-compose.cuda.yml`（已包含在项目中）：

```yaml
services:
  whisper-live:
    image: hwdsl2/whisper-live-server:cuda
    container_name: whisper-live
    restart: always
    ports:
      - "9090:9090/tcp"  # WebSocket — 如使用主机反向代理，改为 "127.0.0.1:9090:9090/tcp"
      - "8000:8000/tcp"  # REST API  — 如使用主机反向代理，改为 "127.0.0.1:8000:8000/tcp"
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

## WebSocket 流式传输

`9090` 端口的 WebSocket 接口支持实时音频流转录。客户端发送原始 PCM 音频块，服务器在解码时返回转录段落。

### 协议

连接后，首先发送 JSON 配置消息：

```json
{
  "uid": "unique-client-id",
  "language": "zh",
  "model": "base",
  "use_vad": true
}
```

然后以二进制 WebSocket 帧形式流式传输 16 kHz 采样率的 16 位 PCM 原始音频。服务器返回 JSON 转录事件：

```json
{"uid": "unique-client-id", "segments": [{"text": "您好，最近怎么样？", "start": 0.0, "end": 2.4, "completed": true}]}
```

### Python 客户端示例

上游 `whisper-live` 0.9.0 客户端没有 API 密钥参数。以下适配器在 WebSocket 握手时发送 Bearer 请求头，并保留文件和麦克风转录功能。运行 Python 示例前，请安装匹配版本的客户端并导出服务器密钥：

```bash
pip install whisper-live==0.9.0
export WHISPERLIVE_API_KEY="$(docker exec whisper-live whisper_live_manage --getkey)"
```

如果已禁用 API 密钥认证，请将 `WHISPERLIVE_API_KEY` 设置为空字符串。

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
    "您的服务器IP",
    9090,
    lang="zh",
    translate=False,
    model="base",
    use_vad=True,
)
client = TranscriptionTeeClient([connection])

# 转录文件
client("audio.mp3")

# 或从麦克风转录
# client()
```

### 浏览器客户端示例

```javascript
const apiKey = "您的API密钥";
const ws = new WebSocket(`ws://您的服务器IP:9090/?token=${encodeURIComponent(apiKey)}`);

ws.onopen = () => {
  // 发送配置信息
  ws.send(JSON.stringify({
    uid: "browser-client-1",
    language: "zh",
    model: "base",
    use_vad: true,
  }));
};

ws.onmessage = (event) => {
  const data = JSON.parse(event.data);
  if (data.segments) {
    data.segments.forEach(seg => console.log(seg.text));
  }
};

// 以 ArrayBuffer 形式发送音频块（16 位 PCM，16 kHz）
// ws.send(audioBuffer);
```

## REST API 参考

`8000` 端口的 REST API 与 [OpenAI 音频转录接口](https://developers.openai.com/api/reference/resources/audio/subresources/transcriptions/methods/create)兼容。使用 OpenAI SDK 的客户端需配置 API 基础 URL 和自托管服务器的 API 密钥：

新的持久化安装需要 API 密钥。获取密钥以用于以下示例：

```bash
scribe_live_api_key="$(docker exec whisper-live whisper_live_manage --getkey)"

export OPENAI_BASE_URL="http://您的服务器IP:8000/v1"
export OPENAI_API_KEY="$scribe_live_api_key"
```

如果已禁用 API 密钥认证，请省略 curl 示例中的 `Authorization` 请求头。OpenAI SDK 客户端仍要求提供非空密钥；此时请设置 `OPENAI_API_KEY=unused`。

### 转录音频

```
POST /v1/audio/transcriptions
Content-Type: multipart/form-data
```

**参数：**

| 参数 | 类型 | 必填 | 说明 |
|---|---|---|---|
| `file` | 文件 | ✅ | 音频文件。支持格式：`mp3`、`mp4`、`m4a`、`wav`、`webm`、`ogg`、`flac` 及 ffmpeg 支持的所有格式。 |
| `model` | 字符串 | — | 省略或传入 `whisper-1` 以使用 `WHISPERLIVE_MODEL`。也可传入受支持的 Whisper 模型规格（如 `small`、`medium`、`large-v3`）、已有的本地模型路径或 Hugging Face 仓库 ID，为本次请求选择其他模型。其他名称会回退到 `WHISPERLIVE_MODEL`；不可用的模型路径或仓库可能导致加载失败。 |
| `language` | 字符串 | — | BCP-47 语言代码（如 `zh`、`en`、`ja`）。如不填，则自动检测语言。 |

**示例：**

```bash
curl http://您的服务器IP:8000/v1/audio/transcriptions \
    -H "Authorization: Bearer $scribe_live_api_key" \
    -F file=@meeting.m4a \
    -F model=whisper-1 \
    -F language=zh
```

**响应：**
```json
{"text": "转录的文字内容显示在这里。"}
```

### 交互式 API 文档

可在以下地址访问交互式 Swagger UI：

```
http://您的服务器IP:8000/docs
```

WhisperLive 0.10.0 的 `/docs`、`/redoc`、`/openapi.json` 和 `/health` 无需 API 密钥认证即可访问。启用认证后，转录请求仍需包含 `Authorization: Bearer <key>`，包括从 Swagger UI 发出的请求。要使用 Swagger UI 进行转录，需要为 API 请求添加该请求头；token 查询参数仅用于 WebSocket 连接认证。

## 持久化数据

所有服务器数据存储在 Docker 数据卷（容器内的 `/var/lib/whisper-live`）中：

```
/var/lib/whisper-live/
├── models--Systran--faster-whisper-*/   # 缓存的 Whisper 模型文件（从 HuggingFace 下载）
├── .ws_port              # 当前 WebSocket 端口（供 whisper_live_manage 使用）
├── .rest_port            # 当前 REST API 端口（供 whisper_live_manage 使用）
├── .model                # 当前模型名称（供 whisper_live_manage 使用）
└── .server_addr          # 缓存的服务器 IP（供 whisper_live_manage 使用）
```

请备份 Docker 数据卷以保留已下载的模型。模型体积较大（145 MB – 3 GB），首次客户端连接时下载可能需要数分钟；保留数据卷可避免在重新创建容器时重复下载。

**提示：** `/var/lib/whisper-live` 数据卷与 ScribeCrate 的 `/var/lib/whisper` 数据卷使用相同的 HuggingFace 缓存布局。如果已通过 ScribeCrate 下载了模型，可绑定挂载相同的数据卷目录以避免重复下载。

## 管理服务器

在运行中的容器内使用 `whisper_live_manage` 来查看和管理服务器。

**显示服务器信息：**

```bash
docker exec whisper-live whisper_live_manage --showinfo
```

**列出可用模型：**

```bash
docker exec whisper-live whisper_live_manage --listmodels
```

**预先下载模型：**

```bash
docker exec whisper-live whisper_live_manage --downloadmodel large-v3-turbo
```

## 切换模型

要更换活跃模型：

1. *（可选但建议）* 在服务器运行时预先下载新模型：
   ```bash
   docker exec whisper-live whisper_live_manage --downloadmodel large-v3-turbo
   ```

2. 在 `whisper-live.env` 文件中更新 `WHISPERLIVE_MODEL`。

3. 重启容器：
   ```bash
   docker restart whisper-live
   ```

**可用模型：**

| 模型 | 磁盘占用 | 内存（约） | 说明 |
|---|---|---|---|
| `tiny` | ~75 MB | ~250 MB | 最快；精度较低 |
| `tiny.en` | ~75 MB | ~250 MB | 仅英语 |
| `base` | ~145 MB | ~700 MB | 良好平衡 — **默认** |
| `base.en` | ~145 MB | ~700 MB | 仅英语 |
| `small` | ~465 MB | ~1.5 GB | 更高精度 |
| `small.en` | ~465 MB | ~1.5 GB | 仅英语 |
| `medium` | ~1.5 GB | ~5 GB | 高精度 |
| `medium.en` | ~1.5 GB | ~5 GB | 仅英语 |
| `large-v1` | ~3 GB | ~10 GB | 旧版大型模型 |
| `large-v2` | ~3 GB | ~10 GB | 非常高精度 |
| `large-v3` | ~3 GB | ~10 GB | 最高精度 |
| `large-v3-turbo` | ~1.6 GB | ~6 GB | 高速 + 高精度 ⭐ |
| `turbo` | ~1.6 GB | ~6 GB | `large-v3-turbo` 的别名 |

> **提示：** `large-v3-turbo` 的精度接近 `large-v3`，但资源消耗约为其一半。对于大多数生产环境，推荐从 `base` 升级到此模型。

内存数据为近似值，基于 INT8 量化（默认）。模型缓存在 `/var/lib/whisper-live` Docker 数据卷中，只需下载一次。

## 保护你的服务器

如果你的 ScribeCrate Live 服务器可从公网访问 —— 即使只是短暂可达 —— 也请至少采取以下保护措施。ScribeCrate Live 对 CPU/GPU 资源消耗较大，未做防护的接口可能被滥用，浪费你的计算资源。

**1. 使用 API 密钥。** 挂载 `/var/lib/whisper-live` 数据卷的新安装会自动生成 API 密钥。可用 `docker exec whisper-live whisper_live_manage --showkey` 查看；脚本中可用 `docker exec whisper-live whisper_live_manage --getkey`。没有密钥的既有安装会保持开放以兼容旧行为；也可以在 `env` 文件中设置 `WHISPERLIVE_API_KEY` 手动启用认证。REST 转录客户端需发送 `Authorization: Bearer <key>`；WebSocket 客户端可发送相同请求头或在 URL 中添加 `?token=<key>`。

**2. 在反向代理后面时绑定到 localhost。** 将 `-p 9090:9090 -p 8000:8000` 替换为 `-p 127.0.0.1:9090:9090 -p 127.0.0.1:8000:8000`（或在 `docker-compose.yml` 中将两个端口映射改为各自的 `127.0.0.1:` 等效形式），使未加密端口无法从主机外部直接访问。

**3. 在代理处限制上传大小。** 音频文件可能很大；配置反向代理以拒绝超大上传（例如 nginx `client_max_body_size 100M;`），从而限制单个请求占用的磁盘和内存。

**4. 注意日志级别。** `WHISPERLIVE_LOG_LEVEL=DEBUG` 可能会将转录文本写入日志。在共享系统上请保持 `INFO` 或更高级别。

**5. 在代理处限制 WebSocket 来源。** 来自不受信任浏览器来源的 WebSocket 连接可在反向代理处被拦截。对于 nginx，在升级连接前检查 `$http_origin`；对于 Caddy，使用 `header` 指令验证 `Origin` 标头。

**6. 考虑限流。** 在服务器前部署限流（如 nginx `limit_req_zone`、Caddy `rate_limit`），限制每个客户端 IP 的并发转录请求数。

## 使用反向代理

如需面向公网部署，可在服务器前置反向代理处理 HTTPS 和 WSS（安全 WebSocket）终止。

可使用以下地址从反向代理访问容器：

- **`whisper-live:9090`** / **`whisper-live:8000`** — 如果反向代理作为容器运行在**同一 Docker 网络**中。
- **`127.0.0.1:9090`** / **`127.0.0.1:8000`** — 如果反向代理运行在**主机上**且端口已发布。

**使用 [Caddy](https://caddyserver.com/docs/)（[Docker 镜像](https://hub.docker.com/_/caddy)）的示例**（自动 TLS，同一 Docker 网络中的 WebSocket 代理）：

`Caddyfile`：
```
whisper-live.example.com {
  # WebSocket 流式传输（wss://）
  handle /ws* {
    reverse_proxy whisper-live:9090
  }
  # REST API（https://）
  reverse_proxy whisper-live:8000
}
```

**使用 nginx 的示例**（反向代理运行在主机上）：

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

    # WebSocket 流式传输
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
> WebSocket 代理需要 `proxy_http_version 1.1` 以及 `Upgrade`/`Connection` 请求头。若缺少这些配置，实时流式传输将无法通过 nginx 正常工作。

<details>
<summary><strong>在代理层添加额外身份验证</strong></summary>

服务器支持通过 `WHISPERLIVE_API_KEY` 进行原生 API 密钥验证。对于面向互联网的部署，也可以在反向代理层添加 Bearer 令牌或基本身份验证作为纵深防护。使用 Caddy 的示例（`basicauth` 保护 REST API）：

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

使用 nginx 的示例（在 REST API location 上启用 `auth_basic`）：

```nginx
location /v1/ {
    auth_basic           "WhisperLive";
    auth_basic_user_file /etc/nginx/.htpasswd;
    proxy_pass           http://127.0.0.1:8000;
    proxy_set_header     Host $host;
    proxy_read_timeout   300s;
}
```

非浏览器 WebSocket 客户端可使用 `Authorization` 请求头进行认证。由于浏览器 WebSocket API 无法设置任意请求头，浏览器客户端可使用 `?token=<key>`。为增强安全性，请将端口 `9090` 绑定到 `127.0.0.1` 并置于反向代理之后。

</details>

## 更新 Docker 镜像

如需更新 Docker 镜像和容器，首先[下载](#下载)最新版本：

```bash
docker pull hwdsl2/whisper-live-server
```

如果镜像已是最新版本，您将看到：

```
Status: Image is up to date for hwdsl2/whisper-live-server:latest
```

否则将下载最新版本。删除并重新创建容器：

```bash
docker rm -f whisper-live
# 然后使用相同的数据卷和端口重新运行快速开始中的 docker run 命令。
```

您下载的模型将保留在 `whisper-live-data` 数据卷中。

## 与其他 AI 服务配合使用

ScribeCrate Live 可作为更广泛的自托管 AI 设置中的实时语音转文字服务。

如需完整和轻量级 Docker Compose 技术栈、手动 `docker run` 示例，以及结合 SpeakCrate、EmbedCrate、GatewayCrate、InferCrate、ParseCrate 和 UplinkCrate 的语音/RAG/MCP 流水线示例，请参阅 [Self-Hosted AI Stack](https://github.com/hwdsl2/self-hosted-ai-stack/blob/main/docs/README-zh.md)。

## 使用计数

此镜像使用公开的 GitHub Release 资源下载次数进行匿名聚合使用计数。计数是近似值，不代表唯一用户或活跃安装。镜像不会发送遥测负载，也不会使用私有收集器。仅当服务器成功启动且挂载了 `/var/lib/whisper-live` 卷后，才会以尽力而为方式计数；当该持久化安装首次运行不同镜像构建时，也会再次计数。要退出，请设置 `WHISPERLIVE_DISABLE_USAGE_COUNTS=1`。

## 技术细节

- 基础镜像：`python:3.12-slim`（Debian）
- 运行时：Python 3（虚拟环境位于 `/opt/venv`）
- STT 引擎：[WhisperLive](https://github.com/collabora/WhisperLive) + [faster-whisper](https://github.com/SYSTRAN/faster-whisper) + CTranslate2（CPU 默认 INT8，CUDA 默认 FP16）
- VAD：通过 PyTorch（CPU 或 CUDA，自动检测）使用 [Silero VAD](https://github.com/snakers4/silero-vad)
- WebSocket 服务器：Python `websockets` 库
- REST API 框架：[FastAPI](https://fastapi.tiangolo.com/) + [Uvicorn](https://www.uvicorn.org/)
- 数据目录：`/var/lib/whisper-live`（Docker 数据卷）
- 模型存储：HuggingFace Hub 格式，存储在数据卷中——下载一次，重启后复用

## 授权协议

**注：** 预构建镜像中包含的软件组件（如 WhisperLive、faster-whisper、PyTorch 及其依赖项）均受各自版权持有者所选许可证约束。使用预构建镜像时，用户有责任确保其使用方式符合镜像内所有软件的相关许可证要求。

版权所有 (C) 2026 Lin Song   
本作品采用 [MIT 许可证](https://opensource.org/licenses/MIT)授权。

**WhisperLive** 版权归 Vineet Suryan、Collabora Ltd. 所有，依据 [MIT 许可证](https://github.com/collabora/WhisperLive/blob/main/LICENSE)分发。

**faster-whisper** 版权归 SYSTRAN 所有，依据 [MIT 许可证](https://github.com/SYSTRAN/faster-whisper/blob/master/LICENSE)分发。

本项目是独立的 Docker 封装，与 OpenAI、Collabora 或 SYSTRAN 无关联，未获其背书或赞助。
