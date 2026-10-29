[English](../README.md) | [简体中文](README-zh.md) | [繁體中文](README-zh-Hant.md) | [Русский](README-ru.md)

# ScribeCrate Live

**開源、自託管的即時轉錄伺服器。**

[![建置狀態](https://github.com/hwdsl2/scribecrate-live/actions/workflows/main.yml/badge.svg)](https://github.com/hwdsl2/scribecrate-live/actions/workflows/main.yml) &nbsp;[![Docker Pulls](https://raw.githubusercontent.com/hwdsl2/badges/main/img/docker-pulls-whisper-live-server.svg)](https://hub.docker.com/r/hwdsl2/whisper-live-server) &nbsp;[![License: MIT](images/license.svg)](https://opensource.org/licenses/MIT) &nbsp;[![Open In Colab](https://colab.research.google.com/assets/colab-badge.svg)](https://selfhostedaistack.com/scribecrate-live-notebook)

ScribeCrate Live 是一個自託管的即時語音轉文字伺服器，由 [WhisperLive](https://github.com/collabora/WhisperLive) 和 [faster-whisper](https://github.com/SYSTRAN/faster-whisper) 提供支援。它透過 WebSocket 為即時麥克風音訊和音訊串流提供轉錄及語音譯成英語的功能，並透過 OpenAI 相容 REST API 提供音訊檔案轉錄。可使用 Docker 在 CPU 或 NVIDIA GPU 上部署。映像基於 Debian（python:3.12-slim）。

> 本專案原名為 `docker-whisper-live`，由 [hwdsl2](https://github.com/hwdsl2) 維護。Docker 映像名稱仍為 `hwdsl2/whisper-live-server`。

**功能特色：**

- **即時 WebSocket 轉錄：** 轉錄即時麥克風音訊或音訊串流，並逐步回傳分段結果
- **語音譯成英語：** 使用適合的多語言 Whisper 模型，透過 WebSocket 將語音翻譯成英語。
- **相容 OpenAI 的 API：** 透過 `POST /v1/audio/transcriptions` 為相容的 OpenAI SDK 與應用程式提供上傳檔案轉錄。
- **私密的本地處理：** 音訊資料保留在您的伺服器上，不傳送給第三方
- **語音活動偵測 (VAD)：** 自動略過靜音段，實現更快、更乾淨的轉錄
- **Whisper 模型：** 支援所有 Whisper 模型，包括 `tiny`、`base`、`small`、`medium`、`large-v3`、`large-v3-turbo` 等
- **CPU 與 GPU 支援：** 可在 CPU 上執行，或使用 `:cuda` 映像啟用 NVIDIA GPU 加速。
- **離線執行：** 使用預先快取的模型，無需網際網路存取 (`WHISPERLIVE_LOCAL_ONLY`)
- **自動建置：** 透過 [GitHub Actions](https://github.com/hwdsl2/scribecrate-live/actions) 自動建置和發佈

也可作為 [Self-Hosted AI Stack](https://github.com/hwdsl2/self-hosted-ai-stack/blob/main/docs/README-zh-Hant.md) 的一部分使用，一條命令即可部署完整的自託管 AI 技術堆疊。

> 📘 [The Self-Hosted AI Builder’s Guide](https://books2read.com/aiguide?store=amazon) 是一本關於建置、保護和維運自己的私有 AI 技術堆疊的實用指南。

**線上試用：** [在 Colab 中開啟](https://selfhostedaistack.com/scribecrate-live-notebook)（無需 Docker 或本機安裝）

**相關 AI 服務：**

- **語音：** [ScribeCrate](https://github.com/hwdsl2/scribecrate/blob/main/docs/README-zh-Hant.md)、[SpeakCrate](https://github.com/hwdsl2/speakcrate/blob/main/docs/README-zh-Hant.md)
- **文件與檢索：** [ParseCrate](https://github.com/hwdsl2/parsecrate/blob/main/docs/README-zh-Hant.md)、[EmbedCrate](https://github.com/hwdsl2/embedcrate/blob/main/docs/README-zh-Hant.md)
- **模型與閘道：** [InferCrate](https://github.com/hwdsl2/infercrate/blob/main/docs/README-zh-Hant.md)、[GatewayCrate](https://github.com/hwdsl2/gatewaycrate/blob/main/docs/README-zh-Hant.md)、[UplinkCrate](https://github.com/hwdsl2/uplinkcrate/blob/main/docs/README-zh-Hant.md)

## 快速開始

使用以下指令啟動 ScribeCrate Live 伺服器：

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
<summary><strong>GPU 快速開始（NVIDIA CUDA）</strong></summary>

如果您有 NVIDIA GPU，可使用 `:cuda` 映像進行硬體加速推論：

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

**需求：** NVIDIA GPU、[NVIDIA 驅動程式](https://www.nvidia.com/en-us/drivers/) 575.57.08+（Linux）或 576.57+（Windows），以及主機上已安裝 [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html)。`:cuda` 映像僅支援 `linux/amd64`。

</details>

**重要：** 此映像執行預設 `base` 模型需要至少 700 MB 可用記憶體。記憶體為 512 MB 或更少的系統不受支援。

> [!NOTE]
> 如需面向網際網路的部署，請使用[反向代理](#使用反向代理)來新增 HTTPS。同時，請將上述 `docker run` 指令中的 `-p 9090:9090 -p 8000:8000` 替換為 `-p 127.0.0.1:9090:9090 -p 127.0.0.1:8000:8000`，以防止從外部直接存取未加密的連接埠。

首次用戶端連線時，Whisper `base` 模型（約 145 MB）將自動下載並快取。查看記錄確認伺服器已就緒：

```bash
docker logs whisper-live
```

看到 "ScribeCrate Live real-time transcription server is ready" 後：

新的持久化安裝會自動啟用 API 金鑰驗證。取得金鑰：

```bash
scribe_live_api_key="$(docker exec whisper-live whisper_live_manage --getkey)"
```

**連接即時 WebSocket 用戶端：**

```
ws://您的伺服器IP:9090/?token=您的API金鑰
```

**或透過 REST API 轉錄檔案：**

```bash
curl http://您的伺服器IP:8000/v1/audio/transcriptions \
    -H "Authorization: Bearer $scribe_live_api_key" \
    -F file=@audio.mp3 \
    -F model=whisper-1
```

**回應：**
```json
{"text": "轉錄的文字內容顯示在這裡。"}
```

**提示：** 需要範例音訊檔案測試 REST API？可以使用來自 [Azure Samples](https://github.com/Azure-Samples/cognitive-services-speech-sdk) 儲存庫的英語語音範例（WAV 格式，MIT 授權）：

```bash
curl -L -o sample_speech.wav \
    "https://github.com/Azure-Samples/cognitive-services-speech-sdk/raw/master/sampledata/audiofiles/katiesteve.wav"

curl http://您的伺服器IP:8000/v1/audio/transcriptions \
    -H "Authorization: Bearer $scribe_live_api_key" \
    -F file=@sample_speech.wav \
    -F model=whisper-1
```

## ScribeCrate 與 ScribeCrate Live 的選擇

| | [ScribeCrate](https://github.com/hwdsl2/scribecrate/blob/main/docs/README-zh-Hant.md) | **ScribeCrate Live** |
|---|---|---|
| **使用情境** | 轉錄完整音訊檔案 | 即時麥克風/音訊串流 |
| **協定** | HTTP REST | WebSocket（串流）+ HTTP REST |
| **語音譯成英語** | 檔案 REST API：`/v1/audio/translations` | WebSocket：`task: "translate"`；REST 提供檔案轉錄 |
| **延遲** | 處理完成後回傳 JSON；SSE 逐段回傳 | 逐步回傳分段結果 |
| **適合** | 會議錄音、上傳的音訊檔案 | 瀏覽器擷取、RTSP 串流、即時字幕 |
| **映像大小** | ~190 MB（`:cuda` 約 3.1 GB） | ~750 MB（`:cuda` 約 4.5 GB） |

## 社群

- 📬 [取得專案更新與免費部署指南](https://selfhostedstack.beehiiv.com/subscribe?utm_campaign=ai-zh-hant)（每月 1–2 封電子郵件；指南為英文 PDF）
- 💬 加入 [r/selfhostedstack](https://www.reddit.com/r/selfhostedstack/) 社群，參與討論與專案展示
- ⭐ 如果你覺得本專案有用，請為儲存庫加星——這能幫助更多人發現它。

<details>
<summary>自託管 VPN 與網路專案</summary>

- [Setup IPsec VPN](https://github.com/hwdsl2/setup-ipsec-vpn/blob/master/README-zh-Hant.md)
- [Docker 上的 IPsec VPN](https://github.com/hwdsl2/docker-ipsec-vpn-server/blob/master/README-zh-Hant.md)
- [WireGuard](https://github.com/hwdsl2/docker-wireguard/blob/main/docs/README-zh-Hant.md)
- [OpenVPN](https://github.com/hwdsl2/docker-openvpn/blob/main/docs/README-zh-Hant.md)
- [Headscale](https://github.com/hwdsl2/docker-headscale/blob/main/docs/README-zh-Hant.md)

</details>

## 系統需求

- 已安裝 Docker 的 Linux 伺服器（本地或雲端）
- 支援的架構：`amd64`（x86_64）、`arm64`（例如 Raspberry Pi 4/5、AWS Graviton）
- 最低記憶體：預設 `base` 模型約需 700 MB 可用記憶體（請參閱[模型清單](#切換模型)）
- 首次啟動需要存取網際網路以下載模型（之後模型將快取在本地）。使用預先快取的模型並設定 `WHISPERLIVE_LOCAL_ONLY=true` 時不需要網路存取。

**GPU 加速（`:cuda` 映像）需求：**

- 支援 CUDA 的 NVIDIA GPU（運算能力 6.0+）
- 主機已安裝 [NVIDIA 驅動程式](https://www.nvidia.com/en-us/drivers/) 575.57.08+（Linux）或 576.57+（Windows）
- 已安裝 [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html)
- `:cuda` 映像僅支援 `linux/amd64`

如需面向公網部署，請參閱[使用反向代理](#使用反向代理)以啟用 HTTPS。

## 下載

從 [Docker Hub](https://hub.docker.com/r/hwdsl2/whisper-live-server/) 取得可信任的建置版本：

```bash
docker pull hwdsl2/whisper-live-server
```

如需 NVIDIA GPU 加速，請拉取 `:cuda` 標籤：

```bash
docker pull hwdsl2/whisper-live-server:cuda
```

也可從 [Quay.io](https://quay.io/repository/hwdsl2/whisper-live-server) 下載：

```bash
docker pull quay.io/hwdsl2/whisper-live-server
docker image tag quay.io/hwdsl2/whisper-live-server hwdsl2/whisper-live-server
```

支援平台：`linux/amd64` 和 `linux/arm64`。`:cuda` 標籤僅支援 `linux/amd64`。

## 環境變數

所有變數均為選填。掛載 `/var/lib/whisper-live` 資料卷的新安裝會自動產生 API 金鑰。沒有金鑰的既有安裝會保持開放以相容舊行為。

此 Docker 映像使用以下變數，可在 `env` 檔案中宣告（參見[範例](../whisper-live.env.example)）：

| 變數 | 說明 | 預設值 |
|---|---|---|
| `WHISPERLIVE_MODEL` | WebSocket 轉錄/翻譯使用的模型，也是 REST 的預設模型。請參閱[模型清單](#切換模型)。 | `base` |
| `WHISPERLIVE_PORT` | 即時串流用戶端的 WebSocket 連接埠（1–65535）。 | `9090` |
| `WHISPERLIVE_REST_PORT` | OpenAI 相容 REST API 的 HTTP 連接埠（1–65535）。 | `8000` |
| `WHISPERLIVE_MAX_CLIENTS` | 最大同時 WebSocket 用戶端連線數。 | `4` |
| `WHISPERLIVE_MAX_CONNECTION_TIME` | WebSocket 最大連線時長（秒）。超過此時長的用戶端將被自動斷線。 | `600` |
| `WHISPERLIVE_THREADS` | 推理使用的 CPU 執行緒數。設為實體核心數可獲得最佳延遲。 | `2` |
| `WHISPERLIVE_API_KEY` | 選用 API 金鑰。新持久化安裝會自動產生。REST 轉錄請求須包含 `Authorization: Bearer <key>`；WebSocket 用戶端可使用 `?token=<key>`。明確設定為空可停用驗證。 | 新持久化安裝自動產生 |
| `WHISPERLIVE_LOG_LEVEL` | 記錄層級：`DEBUG`、`INFO`、`WARNING`、`ERROR`、`CRITICAL`。 | `INFO` |
| `WHISPERLIVE_LOCAL_ONLY` | 設為任意非空值（如 `true`）時，禁止所有 HuggingFace 模型下載。適用於預先快取模型的離線或隔離網路部署。 | *（未設定）* |
| `WHISPERLIVE_DISABLE_USAGE_COUNTS` | 設為 `1` 可停用匿名彙總使用計數。 | *（未設定）* |

WebSocket 用戶端在握手中設定來源語言 `language`（`null` 表示自動偵測）和語音活動偵測 `use_vad`（`true` 啟用，`false` 停用）。REST 用戶端透過請求中的 `language` 指定來源語言，省略時自動偵測。`WHISPERLIVE_LANGUAGE` 和 `WHISPERLIVE_USE_VAD` 只影響啟動日誌中的顯示值，不控制推論設定。

**注意：** 在 `env` 檔案中，值可用單引號括起，例如 `VAR='value'`。`=` 兩側不要有空格。如更改 `WHISPERLIVE_PORT` 或 `WHISPERLIVE_REST_PORT`，請相應更新 `docker run` 指令中的 `-p` 參數。

使用 `env` 檔案的範例：

```bash
cp whisper-live.env.example whisper-live.env
# 編輯 whisper-live.env 設定您的選項，然後：
docker run \
    --name whisper-live \
    --restart=always \
    -v whisper-live-data:/var/lib/whisper-live \
    -v ./whisper-live.env:/whisper-live.env:ro \
    -p 9090:9090 \
    -p 8000:8000 \
    -d hwdsl2/whisper-live-server
```

`env` 檔案以繫結掛載方式傳入容器，每次重新啟動時自動生效，無需重建容器。

<details>
<summary>也可透過 <code>--env-file</code> 傳入</summary>

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
# 依需求編輯 whisper-live.env，然後：
docker compose up -d
docker logs whisper-live
```

示例 `docker-compose.yml`（已包含在專案中）：

```yaml
services:
  whisper-live:
    image: hwdsl2/whisper-live-server
    container_name: whisper-live
    restart: always
    ports:
      - "9090:9090/tcp"  # WebSocket — 如使用主機反向代理，改為 "127.0.0.1:9090:9090/tcp"
      - "8000:8000/tcp"  # REST API  — 如使用主機反向代理，改為 "127.0.0.1:8000:8000/tcp"
    volumes:
      - whisper-live-data:/var/lib/whisper-live
      - ./whisper-live.env:/whisper-live.env:ro

volumes:
  whisper-live-data:
    name: whisper-live-data
```

> [!NOTE]
> 如需面向公網部署，請使用[反向代理](#使用反向代理)啟用 HTTPS。同時，請將 `docker-compose.yml` 中的連接埠改為其 `127.0.0.1:` 形式。

<details>
<summary><strong>使用 docker-compose 部署 GPU（NVIDIA CUDA）</strong></summary>

專案提供了單獨的 `docker-compose.cuda.yml` 用於 GPU 部署：

```bash
cp whisper-live.env.example whisper-live.env
# 依需求編輯 whisper-live.env，然後：
docker compose -f docker-compose.cuda.yml up -d
docker logs whisper-live
```

示例 `docker-compose.cuda.yml`（已包含在專案中）：

```yaml
services:
  whisper-live:
    image: hwdsl2/whisper-live-server:cuda
    container_name: whisper-live
    restart: always
    ports:
      - "9090:9090/tcp"  # WebSocket — 如使用主機反向代理，改為 "127.0.0.1:9090:9090/tcp"
      - "8000:8000/tcp"  # REST API  — 如使用主機反向代理，改為 "127.0.0.1:8000:8000/tcp"
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

## WebSocket 串流

`9090` 連接埠的 WebSocket 端點支援即時音訊串流轉錄及語音譯成英語。用戶端傳送原始 PCM 音訊區塊，伺服器在解碼時回傳文字分段。

### 協議

連線後，首先傳送 JSON 設定訊息：

```json
{
  "uid": "unique-client-id",
  "language": "zh",
  "model": "base",
  "task": "transcribe",
  "audio_format": "float32",
  "use_vad": true
}
```

傳送音訊前，請等待伺服器回傳 `SERVER_READY` 訊息。然後以二進位 WebSocket 幀傳送 **16 kHz、單聲道 float32 PCM** 原始音訊，取樣值正規化至 [-1, 1]。不要在這些幀中傳送 WAV 檔頭或壓縮音訊。伺服器回傳 JSON 文字分段事件：

```json
{"uid": "unique-client-id", "segments": [{"text": "您好，最近怎麼樣？", "start": 0.0, "end": 2.4, "completed": true}]}
```

### Python 用戶端範例

上游 `whisper-live` 0.9.0 用戶端沒有 API 金鑰參數。以下配接器在 WebSocket 交握時傳送 Bearer 標頭，並保留檔案和麥克風轉錄功能。執行 Python 範例前，請安裝相符版本的用戶端並匯出伺服器金鑰：

```bash
pip install whisper-live==0.9.0
export WHISPERLIVE_API_KEY="$(docker exec whisper-live whisper_live_manage --getkey)"
```

如果已停用 API 金鑰驗證，請將 `WHISPERLIVE_API_KEY` 設為空字串。

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
    "您的伺服器IP",
    9090,
    lang="zh",
    translate=False,
    model="base",
    use_vad=True,
)
client = TranscriptionTeeClient([connection])

# 轉錄檔案
client("audio.mp3")

# 或從麥克風轉錄
# client()
```

### 將語音翻譯成英語

重用上方 Python 範例中的 `AuthenticatedClient` 配接器及已匯出的 API 金鑰。設定 `translate=True` 即可請求 Whisper 的語音譯成英語任務：

```python
connection = AuthenticatedClient(
    "您的伺服器IP",
    9090,
    lang="es",
    translate=True,
    model="base",
    use_vad=True,
)
client = TranscriptionTeeClient([connection])

# 輸入為西班牙語音訊，輸出文字為英語
client("spanish.wav")
```

這裡的 `lang="es"` 指定的是**來源語言**，而非輸出語言。設定 `lang=None` 可自動偵測來源語言；直接使用 WebSocket 的用戶端應設定 `"language": null`。直接使用協議時，在上方已驗證的交握設定中加入 `"task": "translate"`。輸出為英語；此任務不能指定任意目標語言。

此範例可使用伺服器預設的多語言 `base` 模型。WebSocket 推論使用**伺服器端 `WHISPERLIVE_MODEL`** 設定的模型；在此映像中，用戶端的 `model` 欄位不會覆寫該設定。若要使用其他模型，請修改伺服器設定，並[依設定方式重新啟動或重新建立容器](#環境變數)。請選擇 `base`、`small`、`medium` 或 `large-v3` 等非 turbo 多語言模型。僅支援英語的 `.en` 模型不支援此任務；`large-v3-turbo` / `turbo` 未針對翻譯任務訓練，不適合可靠的翻譯。

翻譯功能透過 WebSocket 提供。此映像的 REST API 透過 `/v1/audio/transcriptions` 提供**檔案轉錄**，不提供 `/v1/audio/translations` 端點。

### 瀏覽器用戶端範例

```javascript
const apiKey = "您的API金鑰";
const ws = new WebSocket(`ws://您的伺服器IP:9090/?token=${encodeURIComponent(apiKey)}`);

let serverReady = false;

ws.onopen = () => {
  // 傳送設定資訊
  ws.send(JSON.stringify({
    uid: "browser-client-1",
    language: "zh",
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

// 取樣資料須已轉換為單聲道、正規化至 [-1, 1]，並重新取樣至 16 kHz。
function sendAudio(samples) {
  if (!serverReady || ws.readyState !== WebSocket.OPEN) return;
  const chunk = new Float32Array(samples);
  ws.send(chunk.buffer);
}
```

## REST API 參考

翻譯功能透過 WebSocket 提供。此映像的 REST API 透過 `/v1/audio/transcriptions` 提供**檔案轉錄**，不提供 `/v1/audio/translations` 端點。

`8000` 連接埠的 REST API 與 [OpenAI 音訊轉錄端點](https://developers.openai.com/api/reference/resources/audio/subresources/transcriptions/methods/create)相容。使用 OpenAI SDK 的用戶端需設定 API 基礎 URL 和自架伺服器的 API 金鑰：

新的持久化安裝需要 API 金鑰。取得金鑰以用於以下範例：

```bash
scribe_live_api_key="$(docker exec whisper-live whisper_live_manage --getkey)"

export OPENAI_BASE_URL="http://您的伺服器IP:8000/v1"
export OPENAI_API_KEY="$scribe_live_api_key"
```

如果已停用 API 金鑰驗證，請省略 curl 範例中的 `Authorization` 標頭。OpenAI SDK 用戶端仍要求提供非空金鑰；此時請設定 `OPENAI_API_KEY=unused`。

### 轉錄音訊

```
POST /v1/audio/transcriptions
Content-Type: multipart/form-data
```

**參數：**

| 參數 | 類型 | 必填 | 說明 |
|---|---|---|---|
| `file` | 檔案 | ✅ | 音訊檔案。支援格式：`mp3`、`mp4`、`m4a`、`wav`、`webm`、`ogg`、`flac` 及 ffmpeg 支援的所有格式。 |
| `model` | 字串 | — | 省略或傳入 `whisper-1` 以使用 `WHISPERLIVE_MODEL`。也可傳入支援的 Whisper 模型規格（如 `small`、`medium`、`large-v3`）、現有的本機模型路徑或 Hugging Face 儲存庫 ID，為本次請求選擇其他模型。其他名稱會回退到 `WHISPERLIVE_MODEL`；無法使用的模型路徑或儲存庫可能導致載入失敗。 |
| `language` | 字串 | — | BCP-47 語言代碼（如 `zh`、`en`、`ja`）。如不填，則自動偵測語言。 |

**範例：**

```bash
curl http://您的伺服器IP:8000/v1/audio/transcriptions \
    -H "Authorization: Bearer $scribe_live_api_key" \
    -F file=@meeting.m4a \
    -F model=whisper-1 \
    -F language=zh
```

**回應：**
```json
{"text": "轉錄的文字內容顯示在這裡。"}
```

### 互動式 API 文件

互動式 Swagger UI 可在以下位址存取：

```
http://您的伺服器IP:8000/docs
```

WhisperLive 0.10.0 的 `/docs`、`/redoc`、`/openapi.json` 和 `/health` 無需 API 金鑰驗證即可存取。啟用驗證後，轉錄請求仍需包含 `Authorization: Bearer <key>`，包括從 Swagger UI 發出的請求。要使用 Swagger UI 進行轉錄，需要為 API 請求加上該標頭；token 查詢參數僅用於 WebSocket 連線驗證。

## 持久化資料

所有伺服器資料儲存在 Docker 資料卷（容器內的 `/var/lib/whisper-live`）中：

```
/var/lib/whisper-live/
├── models--Systran--faster-whisper-*/   # 快取的 Whisper 模型檔案（從 HuggingFace 下載）
├── .ws_port              # 當前 WebSocket 連接埠（供 whisper_live_manage 使用）
├── .rest_port            # 當前 REST API 連接埠（供 whisper_live_manage 使用）
├── .model                # 當前模型名稱（供 whisper_live_manage 使用）
└── .server_addr          # 快取的伺服器 IP（供 whisper_live_manage 使用）
```

請備份 Docker 資料卷以保留已下載的模型。模型體積較大（145 MB – 3 GB），首次用戶端連線時下載可能需要數分鐘；保留資料卷可避免在重新建立容器時重複下載。

**提示：** `/var/lib/whisper-live` 資料卷與 ScribeCrate 的 `/var/lib/whisper` 資料卷使用相同的 HuggingFace 快取配置。如果已透過 ScribeCrate 下載了模型，可繫結掛載相同的資料卷目錄以避免重複下載。

## 管理伺服器

在執行中的容器內使用 `whisper_live_manage` 來查看和管理伺服器。

```bash
docker exec whisper-live whisper_live_manage --showinfo
docker exec whisper-live whisper_live_manage --listmodels
docker exec whisper-live whisper_live_manage --downloadmodel large-v3-turbo
```

## 切換模型

1. *（選填但建議）* 預先下載新模型：
   ```bash
   docker exec whisper-live whisper_live_manage --downloadmodel large-v3-turbo
   ```
2. 在 `whisper-live.env` 檔案中更新 `WHISPERLIVE_MODEL`。
3. 若使用繫結掛載的 env 檔案，請重新啟動容器；若使用 `--env-file` 或 `-e`，請重新建立容器以套用新設定：
   ```bash
   docker restart whisper-live
   ```

**可用模型：**

| 模型 | 磁碟占用 | 記憶體（約） | 說明 |
|---|---|---|---|
| `tiny` | ~75 MB | ~250 MB | 最快；精確度較低 |
| `tiny.en` | ~75 MB | ~250 MB | 僅英語 |
| `base` | ~145 MB | ~700 MB | 良好平衡 — **預設** |
| `base.en` | ~145 MB | ~700 MB | 僅英語 |
| `small` | ~465 MB | ~1.5 GB | 更高精確度 |
| `small.en` | ~465 MB | ~1.5 GB | 僅英語 |
| `medium` | ~1.5 GB | ~5 GB | 高精確度 |
| `medium.en` | ~1.5 GB | ~5 GB | 僅英語 |
| `large-v1` | ~3 GB | ~10 GB | 舊版大型模型 |
| `large-v2` | ~3 GB | ~10 GB | 非常高精確度 |
| `large-v3` | ~3 GB | ~10 GB | 最高精確度 |
| `large-v3-turbo` | ~1.6 GB | ~6 GB | 高速 + 高精確度 ⭐；僅用於轉錄 |
| `turbo` | ~1.6 GB | ~6 GB | `large-v3-turbo` 的別名；僅用於轉錄 |

> **提示：** 對於轉錄，在硬體資源充足時，`large-v3-turbo` 是比 `large-v3` 更快的選擇。若要將語音翻譯成英語，請選擇 `base`、`small`、`medium` 或 `large-v3` 等非 turbo 多語言模型。

RAM 數值僅供粗略規劃，不是實測需求，也不代表 GPU 顯示記憶體需求。CPU 後端使用 INT8；CUDA 後端在運算能力 7.0+ 的 GPU 上使用 FP16，在較舊的受支援 GPU 上使用 FP32。實際記憶體和顯示記憶體用量取決於模型、音訊長度及並行用戶端數量。模型快取於 `/var/lib/whisper-live` Docker 資料卷中，僅需下載一次。

## 保護你的伺服器

如果你的 ScribeCrate Live 伺服器可從公用網際網路存取 —— 即使只是短暫可達 —— 也請至少採取以下保護措施。ScribeCrate Live 對 CPU/GPU 資源消耗較大，未做防護的介面可能被濫用，浪費你的運算資源。

**1. 使用 API 金鑰。** 掛載 `/var/lib/whisper-live` 資料卷的新安裝會自動產生 API 金鑰。可用 `docker exec whisper-live whisper_live_manage --showkey` 查看；腳本中可用 `docker exec whisper-live whisper_live_manage --getkey`。沒有金鑰的既有安裝會保持開放以相容舊行為；也可以在 `env` 檔案中設定 `WHISPERLIVE_API_KEY` 手動啟用驗證。REST 轉錄用戶端需傳送 `Authorization: Bearer <key>`；WebSocket 用戶端可傳送相同標頭或在 URL 中加入 `?token=<key>`。

**2. 在反向代理後方時繫結到 localhost。** 將 `-p 9090:9090 -p 8000:8000` 替換為 `-p 127.0.0.1:9090:9090 -p 127.0.0.1:8000:8000`（或在 `docker-compose.yml` 中將兩個連接埠對應改為各自的 `127.0.0.1:` 等效形式），使未加密連接埠無法從主機外部直接存取。

**3. 在代理處限制上傳大小。** 音訊檔案可能很大；設定反向代理以拒絕過大的上傳（例如 nginx `client_max_body_size 100M;`），從而限制單一請求佔用的磁碟和記憶體。

**4. 注意日誌等級。** `WHISPERLIVE_LOG_LEVEL=DEBUG` 可能會將轉錄文字寫入日誌。在共用系統上請保持 `INFO` 或更高等級。

**5. 在代理處限制 WebSocket 來源。** 來自不受信任瀏覽器來源的 WebSocket 連線可在反向代理處被攔截。對於 nginx，在升級連線前檢查 `$http_origin`；對於 Caddy，使用 `header` 指令驗證 `Origin` 標頭。

**6. 考慮限流。** 在伺服器前部署限流（如 nginx `limit_req_zone`、Caddy `rate_limit`），限制每個用戶端 IP 的並行轉錄請求數。

## 使用反向代理

可使用以下位址從反向代理存取容器：

- **`whisper-live:9090`** / **`whisper-live:8000`** — 如果反向代理以容器形式執行在**相同 Docker 網路**中。
- **`127.0.0.1:9090`** / **`127.0.0.1:8000`** — 如果反向代理執行在**主機上**且連接埠已發佈。

**使用 [Caddy](https://caddyserver.com/docs/)（[Docker 映像](https://hub.docker.com/_/caddy)）的範例**（自動 TLS，同一 Docker 網路中的 WebSocket 代理）：

`Caddyfile`：
```
whisper-live.example.com {
  # WebSocket 串流（wss://）
  handle /ws* {
    reverse_proxy whisper-live:9090
  }
  # REST API（https://）
  reverse_proxy whisper-live:8000
}
```

**使用 nginx 的範例**（反向代理執行在主機上）：

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

    # WebSocket 串流
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
> WebSocket 代理需要 `proxy_http_version 1.1` 以及 `Upgrade`/`Connection` 請求標頭。若缺少這些設定，即時串流將無法透過 nginx 正常運作。

<details>
<summary><strong>在代理層新增額外身份驗證</strong></summary>

伺服器支援透過 `WHISPERLIVE_API_KEY` 進行原生 API 金鑰驗證。對於面向網際網路的部署，也可以在反向代理層新增 Bearer 令牌或基本身份驗證作為縱深防護。使用 Caddy 的範例（`basicauth` 保護 REST API）：

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

使用 nginx 的範例（在 REST API location 上啟用 `auth_basic`）：

```nginx
location /v1/ {
    auth_basic           "WhisperLive";
    auth_basic_user_file /etc/nginx/.htpasswd;
    proxy_pass           http://127.0.0.1:8000;
    proxy_set_header     Host $host;
    proxy_read_timeout   300s;
}
```

非瀏覽器 WebSocket 用戶端可使用 `Authorization` 標頭進行驗證。由於瀏覽器 WebSocket API 無法設定任意標頭，瀏覽器用戶端可使用 `?token=<key>`。為加強安全性，請將連接埠 `9090` 繫結至 `127.0.0.1` 並置於反向代理之後。

</details>

## 更新 Docker 映像

```bash
docker pull hwdsl2/whisper-live-server
docker rm -f whisper-live
# 然後使用相同的資料卷和連接埠重新執行快速開始中的 docker run 指令。
```

您下載的模型將保留在 `whisper-live-data` 資料卷中。

## 與其他 AI 服務搭配使用

ScribeCrate Live 可作為更廣泛的自託管 AI 設定中的即時語音轉文字服務。

如需完整和輕量級 Docker Compose 技術堆疊、手動 `docker run` 範例，以及結合 SpeakCrate、EmbedCrate、GatewayCrate、InferCrate、ParseCrate 和 UplinkCrate 的語音/RAG/MCP 流水線範例，請參閱 [Self-Hosted AI Stack](https://github.com/hwdsl2/self-hosted-ai-stack/blob/main/docs/README-zh-Hant.md)。

## 使用計數

此映像使用公開的 GitHub Release 資源下載次數進行匿名彙總使用計數。計數是近似值，不代表唯一使用者或活躍安裝。映像不會傳送遙測負載，也不會使用私有收集器。僅當伺服器成功啟動且掛載了 `/var/lib/whisper-live` 卷後，才會以盡力而為方式計數；當該持久化安裝首次執行不同映像建置時，也會再次計數。若要退出，請設定 `WHISPERLIVE_DISABLE_USAGE_COUNTS=1`。

## 技術細節

- 基礎映像：`python:3.12-slim`（Debian）
- 執行環境：Python 3（虛擬環境位於 `/opt/venv`）
- STT 引擎：[WhisperLive](https://github.com/collabora/WhisperLive) + [faster-whisper](https://github.com/SYSTRAN/faster-whisper) + CTranslate2（CPU 使用 INT8，CUDA 使用 FP16/FP32）
- VAD：透過 PyTorch（CPU 或 CUDA，自動偵測）使用 [Silero VAD](https://github.com/snakers4/silero-vad)
- WebSocket 伺服器：Python `websockets` 函式庫
- REST API 框架：[FastAPI](https://fastapi.tiangolo.com/) + [Uvicorn](https://www.uvicorn.org/)
- 資料目錄：`/var/lib/whisper-live`（Docker 資料卷）
- 模型儲存：HuggingFace Hub 格式，存於資料卷中——下載一次，重新啟動後複用

## 授權條款

**注意：** 預建映像中包含的軟體元件（如 WhisperLive、faster-whisper、PyTorch 及其相依套件）均受各自版權持有者所選授權條款約束。使用預建映像時，使用者有責任確保其使用方式符合映像內所有軟體的相關授權條款要求。

版權所有 (C) 2026 Lin Song   
本作品採用 [MIT 授權條款](https://opensource.org/licenses/MIT)授權。

**WhisperLive** 版權歸 Vineet Suryan、Collabora Ltd. 所有，依據 [MIT 授權條款](https://github.com/collabora/WhisperLive/blob/main/LICENSE)散布。

**faster-whisper** 版權歸 SYSTRAN 所有，依據 [MIT 授權條款](https://github.com/SYSTRAN/faster-whisper/blob/master/LICENSE)散布。

本專案是獨立的 Docker 封裝，與 OpenAI、Collabora 或 SYSTRAN 無關聯，未獲其背書或贊助。
