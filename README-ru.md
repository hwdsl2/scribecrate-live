[English](README.md) | [简体中文](README-zh.md) | [繁體中文](README-zh-Hant.md) | [Русский](README-ru.md)

# ScribeCrate Live

**Сервер транскрипции в реальном времени с открытым исходным кодом для самостоятельного размещения.**

[![Статус сборки](https://github.com/hwdsl2/scribecrate-live/actions/workflows/main.yml/badge.svg)](https://github.com/hwdsl2/scribecrate-live/actions/workflows/main.yml) &nbsp;[![Docker Pulls](https://raw.githubusercontent.com/hwdsl2/badges/main/img/docker-pulls-whisper-live-server.svg)](https://hub.docker.com/r/hwdsl2/whisper-live-server) &nbsp;[![License: MIT](docs/images/license.svg)](https://opensource.org/licenses/MIT) &nbsp;[![Open In Colab](https://colab.research.google.com/assets/colab-badge.svg)](https://selfhostedaistack.com/scribecrate-live-notebook)

ScribeCrate Live представляет собой сервер транскрипции речи в реальном времени для самостоятельного размещения на базе [WhisperLive](https://github.com/collabora/WhisperLive) и [faster-whisper](https://github.com/SYSTRAN/faster-whisper). Предоставляет транскрипцию аудио с микрофона и аудиопотоков через WebSocket, а также совместимый с OpenAI REST API для аудиофайлов. Развёртывается с помощью Docker на CPU или NVIDIA GPU. Образ основан на Debian (python:3.12-slim).

> Ранее проект назывался `docker-whisper-live`. Его поддерживает [hwdsl2](https://github.com/hwdsl2). Docker-образ остаётся `hwdsl2/whisper-live-server`.

**Возможности:**

- **Транскрипция по WebSocket в реальном времени:** транскрибирование аудио с микрофона или аудиопотоков с постепенным обновлением сегментов
- **Совместимый с OpenAI API:** `POST /v1/audio/transcriptions` для транскрипции загруженных файлов из совместимых OpenAI SDK и приложений.
- **Конфиденциальная локальная обработка:** Аудио остаётся на вашем сервере — данные не передаются третьим сторонам
- **Определение речевой активности (VAD):** автоматически пропускает тишину для более быстрого и чистого транскрибирования
- **Модели Whisper:** поддержка всех моделей Whisper, включая `tiny`, `base`, `small`, `medium`, `large-v3`, `large-v3-turbo` и другие
- **Поддержка CPU и GPU:** работа на CPU или ускорение на GPU NVIDIA с образом `:cuda`.
- **Работа без интернета:** работа без доступа к интернету с предварительно загруженными моделями (`WHISPERLIVE_LOCAL_ONLY`)
- **Автоматическая сборка:** образы автоматически собираются и публикуются через [GitHub Actions](https://github.com/hwdsl2/scribecrate-live/actions).

Также доступен в составе [Self-Hosted AI Stack](https://github.com/hwdsl2/self-hosted-ai-stack/blob/main/README-ru.md), который развёртывает полный AI-стек на собственном сервере одной командой.

> 📘 [The Self-Hosted AI Builder’s Guide](https://books2read.com/aiguide?store=amazon): практическое руководство по созданию, защите и эксплуатации собственного приватного ИИ-стека.

**Также доступно:**

- Попробовать онлайн: [Открыть в Colab](https://selfhostedaistack.com/scribecrate-live-notebook) — Docker и установка не требуются
- Связанные AI-сервисы: [ScribeCrate](https://github.com/hwdsl2/scribecrate/blob/main/README-ru.md), [SpeakCrate](https://github.com/hwdsl2/speakcrate/blob/main/README-ru.md), [EmbedCrate](https://github.com/hwdsl2/embedcrate/blob/main/README-ru.md), [GatewayCrate](https://github.com/hwdsl2/gatewaycrate/blob/main/README-ru.md), [InferCrate](https://github.com/hwdsl2/infercrate/blob/main/README-ru.md), [ParseCrate](https://github.com/hwdsl2/parsecrate/blob/main/README-ru.md), [UplinkCrate](https://github.com/hwdsl2/uplinkcrate/blob/main/README-ru.md)

## Быстрый старт

Запустите сервер ScribeCrate Live:

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
<summary><strong>Быстрый старт с GPU (NVIDIA CUDA)</strong></summary>

Если у вас есть GPU NVIDIA, используйте образ `:cuda` для аппаратного ускорения инференса:

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

**Требования:** GPU NVIDIA, [драйвер NVIDIA](https://www.nvidia.com/en-us/drivers/) 575.57.08+ (Linux) или 576.57+ (Windows), а также установленный на хосте [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html). Образ `:cuda` поддерживает только `linux/amd64`.

</details>

**Важно:** Для работы образа с моделью `base` по умолчанию требуется не менее 700 МБ свободной оперативной памяти. Системы с 512 МБ ОЗУ и менее не поддерживаются.

> [!NOTE]
> Для развёртывания с доступом из интернета используйте [обратный прокси](#использование-обратного-прокси) для добавления HTTPS. Также замените `-p 9090:9090 -p 8000:8000` на `-p 127.0.0.1:9090:9090 -p 127.0.0.1:8000:8000`.

При первом подключении клиента модель Whisper `base` (~145 МБ) скачивается и кэшируется. Проверьте логи:

```bash
docker logs whisper-live
```

После появления "ScribeCrate Live real-time transcription server is ready":

В новых постоянных установках аутентификация по API-ключу включается автоматически. Получите ключ:

```bash
scribe_live_api_key="$(docker exec whisper-live whisper_live_manage --getkey)"
```

**Подключение WebSocket-клиента в реальном времени:**

```
ws://ip_вашего_сервера:9090/?token=ВАШ_API_КЛЮЧ
```

**Или транскрибирование файла через REST API:**

```bash
curl http://ip_вашего_сервера:8000/v1/audio/transcriptions \
    -H "Authorization: Bearer $scribe_live_api_key" \
    -F file=@audio.mp3 \
    -F model=whisper-1
```

**Ответ:**
```json
{"text": "Транскрибированный текст появляется здесь."}
```

**Совет:** Нужен образец аудиофайла для тестирования REST API? Можно использовать этот образец английской речи (WAV, лицензия MIT) из репозитория [Azure Samples](https://github.com/Azure-Samples/cognitive-services-speech-sdk):

```bash
curl -L -o sample_speech.wav \
    "https://github.com/Azure-Samples/cognitive-services-speech-sdk/raw/master/sampledata/audiofiles/katiesteve.wav"

curl http://ip_вашего_сервера:8000/v1/audio/transcriptions \
    -H "Authorization: Bearer $scribe_live_api_key" \
    -F file=@sample_speech.wav \
    -F model=whisper-1
```

## ScribeCrate и ScribeCrate Live: что выбрать

| | [ScribeCrate](https://github.com/hwdsl2/scribecrate/blob/main/README-ru.md) | **ScribeCrate Live** |
|---|---|---|
| **Назначение** | Транскрибирование готовых аудиофайлов | Живой микрофон / потоковое аудио в реальном времени |
| **Протокол** | HTTP REST | WebSocket (потоковый) + HTTP REST |
| **Задержка** | JSON после обработки; сегменты через SSE | Постепенные обновления сегментов |
| **Подходит для** | Записи совещаний, загруженные аудиофайлы | Захват в браузере, RTSP-потоки, живые субтитры |
| **Размер образа** | ~190 МБ (~3,1 ГБ для `:cuda`) | ~750 МБ (~4,5 ГБ для `:cuda`) |

## Сообщество

- 📬 [Получайте новости проектов и бесплатные руководства по развёртыванию](https://selfhostedstack.beehiiv.com/subscribe?utm_campaign=ai-ru) (1–2 письма в месяц; руководства в формате PDF на английском языке)
- 💬 Присоединяйтесь к сообществу [r/selfhostedstack](https://www.reddit.com/r/selfhostedstack/) для обсуждений и демонстрации проектов
- ⭐ Поставьте звезду репозиторию, если он оказался вам полезен — это поможет другим пользователям его найти.

<details>
<summary>Самостоятельно размещаемые VPN и сетевые проекты</summary>

- [Setup IPsec VPN](https://github.com/hwdsl2/setup-ipsec-vpn/blob/master/README-ru.md)
- [IPsec VPN на Docker](https://github.com/hwdsl2/docker-ipsec-vpn-server/blob/master/README-ru.md)
- [WireGuard](https://github.com/hwdsl2/docker-wireguard/blob/main/README-ru.md)
- [OpenVPN](https://github.com/hwdsl2/docker-openvpn/blob/main/README-ru.md)
- [Headscale](https://github.com/hwdsl2/docker-headscale/blob/main/README-ru.md)

</details>

## Требования

- Сервер Linux (локальный или облачный) с установленным Docker
- Поддерживаемые архитектуры: `amd64` (x86_64), `arm64` (например, Raspberry Pi 4/5, AWS Graviton)
- Минимум ОЗУ: ~700 МБ свободной памяти для модели `base` по умолчанию (см. [таблицу моделей](#смена-модели))
- Доступ к интернету для первоначальной загрузки модели (после чего она кэшируется локально). Не требуется при использовании `WHISPERLIVE_LOCAL_ONLY=true` с предварительно загруженными моделями.

**Для ускорения на GPU (образ `:cuda`):**

- GPU NVIDIA с поддержкой CUDA (Compute Capability 6.0+)
- [Драйвер NVIDIA](https://www.nvidia.com/en-us/drivers/) 575.57.08+ (Linux) или 576.57+ (Windows) на хосте
- Установленный [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html)
- Образ `:cuda` поддерживает только `linux/amd64`

Для развёртывания с выходом в интернет см. раздел [Использование обратного прокси](#использование-обратного-прокси) для включения HTTPS.

## Загрузка

Получить проверенную сборку из [Docker Hub](https://hub.docker.com/r/hwdsl2/whisper-live-server/):

```bash
docker pull hwdsl2/whisper-live-server
```

Для GPU-ускорения NVIDIA используйте тег `:cuda`:

```bash
docker pull hwdsl2/whisper-live-server:cuda
```

Или из [Quay.io](https://quay.io/repository/hwdsl2/whisper-live-server):

```bash
docker pull quay.io/hwdsl2/whisper-live-server
docker image tag quay.io/hwdsl2/whisper-live-server hwdsl2/whisper-live-server
```

Поддерживаемые платформы: `linux/amd64` и `linux/arm64`. Тег `:cuda` поддерживает только `linux/amd64`.

## Переменные окружения

Все переменные необязательны. Новые установки с подключённым томом `/var/lib/whisper-live` автоматически генерируют API-ключ. Существующие установки без ключа остаются открытыми для обратной совместимости.

| Переменная | Описание | По умолчанию |
|---|---|---|
| `WHISPERLIVE_MODEL` | Модель Whisper. См. [таблицу моделей](#смена-модели). | `base` |
| `WHISPERLIVE_LANGUAGE` | Язык транскрибирования по умолчанию. Код BCP-47 (например, `ru`, `en`) или `auto` для автоопределения. | `auto` |
| `WHISPERLIVE_PORT` | Порт WebSocket для потоковых клиентов (1–65535). | `9090` |
| `WHISPERLIVE_REST_PORT` | HTTP-порт совместимого с OpenAI REST API (1–65535). | `8000` |
| `WHISPERLIVE_MAX_CLIENTS` | Максимальное количество одновременных WebSocket-подключений. | `4` |
| `WHISPERLIVE_MAX_CONNECTION_TIME` | Максимальная длительность WebSocket-подключения в секундах. | `600` |
| `WHISPERLIVE_USE_VAD` | Включить обнаружение голосовой активности. `true` — пропускать тишину, `false` — обрабатывать всё аудио непрерывно. | `true` |
| `WHISPERLIVE_THREADS` | Потоки CPU для инференса. Установите равным количеству физических ядер для минимальной задержки. | `2` |
| `WHISPERLIVE_LOG_LEVEL` | Уровень логирования: `DEBUG`, `INFO`, `WARNING`, `ERROR`, `CRITICAL`. | `INFO` |
| `WHISPERLIVE_API_KEY` | Необязательный API-ключ. В новых постоянных установках генерируется автоматически. REST-запросы транскрипции должны содержать `Authorization: Bearer <key>`; WebSocket-клиенты могут использовать `?token=<key>`. Явно пустое значение отключает аутентификацию. | Автоматически для новых постоянных установок |
| `WHISPERLIVE_LOCAL_ONLY` | При установке любого непустого значения (например, `true`) отключает загрузку моделей с HuggingFace. Для офлайн-развёртываний. | *(не задано)* |
| `WHISPERLIVE_DISABLE_USAGE_COUNTS` | Установите `1`, чтобы отключить анонимные агрегированные счётчики использования. | *(не задано)* |

Пример использования env-файла:

```bash
cp whisper-live.env.example whisper-live.env
# Отредактируйте whisper-live.env и запустите:
docker run \
    --name whisper-live \
    --restart=always \
    -v whisper-live-data:/var/lib/whisper-live \
    -v ./whisper-live.env:/whisper-live.env:ro \
    -p 9090:9090 \
    -p 8000:8000 \
    -d hwdsl2/whisper-live-server
```

Файл `env` монтируется в контейнер, изменения применяются при каждом перезапуске без пересоздания контейнера.

<details>
<summary>Либо передайте его через <code>--env-file</code></summary>

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

## Использование docker-compose

```bash
cp whisper-live.env.example whisper-live.env
# Отредактируйте whisper-live.env при необходимости, затем:
docker compose up -d
docker logs whisper-live
```

Пример `docker-compose.yml` (уже включён в проект):

```yaml
services:
  whisper-live:
    image: hwdsl2/whisper-live-server
    container_name: whisper-live
    restart: always
    ports:
      - "9090:9090/tcp"  # WebSocket — для хостового обратного прокси измените на "127.0.0.1:9090:9090/tcp"
      - "8000:8000/tcp"  # REST API  — для хостового обратного прокси измените на "127.0.0.1:8000:8000/tcp"
    volumes:
      - whisper-live-data:/var/lib/whisper-live
      - ./whisper-live.env:/whisper-live.env:ro

volumes:
  whisper-live-data:
    name: whisper-live-data
```

> [!NOTE]
> Для развёртывания с выходом в интернет используйте [обратный прокси](#использование-обратного-прокси) для добавления HTTPS. Также измените порты на их `127.0.0.1:` варианты в `docker-compose.yml`.

<details>
<summary><strong>Использование docker-compose с GPU (NVIDIA CUDA)</strong></summary>

Для развёртывания с GPU используется отдельный файл `docker-compose.cuda.yml`:

```bash
cp whisper-live.env.example whisper-live.env
# Отредактируйте whisper-live.env при необходимости, затем:
docker compose -f docker-compose.cuda.yml up -d
docker logs whisper-live
```

Пример `docker-compose.cuda.yml` (уже включён в проект):

```yaml
services:
  whisper-live:
    image: hwdsl2/whisper-live-server:cuda
    container_name: whisper-live
    restart: always
    ports:
      - "9090:9090/tcp"  # WebSocket — для хостового обратного прокси измените на "127.0.0.1:9090:9090/tcp"
      - "8000:8000/tcp"  # REST API  — для хостового обратного прокси измените на "127.0.0.1:8000:8000/tcp"
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

## Потоковая передача через WebSocket

WebSocket-эндпоинт на порту `9090` поддерживает транскрибирование живых аудиопотоков.

### Протокол

При подключении сначала отправьте JSON-конфигурацию:

```json
{
  "uid": "unique-client-id",
  "language": "ru",
  "model": "base",
  "use_vad": true
}
```

Затем передавайте сырое 16-битное PCM-аудио на частоте 16 кГц бинарными WebSocket-фреймами. Сервер возвращает JSON-события транскрибирования:

```json
{"uid": "unique-client-id", "segments": [{"text": "Привет, как дела?", "start": 0.0, "end": 2.4, "completed": true}]}
```

### Пример Python-клиента

В клиенте `whisper-live` версии 0.9.0 из исходного проекта нет параметра API-ключа. Этот адаптер передаёт заголовок Bearer при установлении WebSocket-соединения и сохраняет транскрибирование файлов и звука с микрофона. Перед запуском примера Python установите соответствующую версию клиента и экспортируйте ключ сервера:

```bash
pip install whisper-live==0.9.0
export WHISPERLIVE_API_KEY="$(docker exec whisper-live whisper_live_manage --getkey)"
```

Если аутентификация по API-ключу отключена, задайте пустую строку в `WHISPERLIVE_API_KEY`.

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
    "ip_вашего_сервера",
    9090,
    lang="ru",
    translate=False,
    model="base",
    use_vad=True,
)
client = TranscriptionTeeClient([connection])

# Транскрибирование файла
client("audio.mp3")

# Или с микрофона
# client()
```

### Пример браузерного клиента

```javascript
const apiKey = "ВАШ_API_КЛЮЧ";
const ws = new WebSocket(`ws://ip_вашего_сервера:9090/?token=${encodeURIComponent(apiKey)}`);

ws.onopen = () => {
  // Отправляем конфигурацию
  ws.send(JSON.stringify({
    uid: "browser-client-1",
    language: "ru",
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

// Отправляем аудиофрагменты как ArrayBuffer (16-бит PCM, 16 кГц)
// ws.send(audioBuffer);
```

## REST API

REST API на порту `8000` совместим с [эндпоинтом OpenAI для транскрибирования аудио](https://developers.openai.com/api/reference/resources/audio/subresources/transcriptions/methods/create). Для клиентов, использующих OpenAI SDK, задайте базовый URL API и API-ключ вашего сервера:

Новые установки с постоянным томом требуют API-ключ. Получите его для следующих примеров:

```bash
scribe_live_api_key="$(docker exec whisper-live whisper_live_manage --getkey)"

export OPENAI_BASE_URL="http://ip_вашего_сервера:8000/v1"
export OPENAI_API_KEY="$scribe_live_api_key"
```

Если аутентификация по API-ключу отключена, опустите заголовок `Authorization` в примерах curl. Клиентам OpenAI SDK по-прежнему нужен непустой ключ; в этом случае задайте `OPENAI_API_KEY=unused`.

### Транскрибирование аудио

```
POST /v1/audio/transcriptions
Content-Type: multipart/form-data
```

**Параметры:**

| Параметр | Тип | Обязательно | Описание |
|---|---|---|---|
| `file` | файл | ✅ | Аудиофайл. Поддерживаемые форматы: `mp3`, `mp4`, `m4a`, `wav`, `webm`, `ogg`, `flac` и все форматы, поддерживаемые ffmpeg. |
| `model` | строка | — | Не указывайте параметр или передайте `whisper-1`, чтобы использовать `WHISPERLIVE_MODEL`. Укажите поддерживаемый размер модели Whisper (например, `small`, `medium`, `large-v3`), существующий локальный путь к модели или ID репозитория Hugging Face, чтобы выбрать другую модель для этого запроса. Другие имена приводят к использованию `WHISPERLIVE_MODEL`; недоступный путь к модели или репозиторий может вызвать ошибку загрузки. |
| `language` | строка | — | Код языка BCP-47 (например, `ru`, `en`, `zh`). Если не указан, язык определяется автоматически. |

**Пример:**

```bash
curl http://ip_вашего_сервера:8000/v1/audio/transcriptions \
    -H "Authorization: Bearer $scribe_live_api_key" \
    -F file=@meeting.m4a \
    -F model=whisper-1 \
    -F language=ru
```

**Ответ:**
```json
{"text": "Транскрибированный текст появляется здесь."}
```

### Интерактивная документация API

Интерактивная документация Swagger UI:

```
http://ip_вашего_сервера:8000/docs
```

В WhisperLive 0.10.0 `/docs`, `/redoc`, `/openapi.json` и `/health` доступны без аутентификации по API-ключу. При включённой аутентификации запросы транскрипции по-прежнему требуют `Authorization: Bearer <key>`, в том числе запросы из Swagger UI. Для транскрипции через Swagger UI обеспечьте отправку этого заголовка в запросах API; параметр token в URL используется только для аутентификации WebSocket-соединений.

## Постоянные данные

Все данные сервера хранятся в Docker-томе (`/var/lib/whisper-live` внутри контейнера):

```
/var/lib/whisper-live/
├── models--Systran--faster-whisper-*/   # Кэшированные файлы модели Whisper (загружены с HuggingFace)
├── .ws_port              # Активный порт WebSocket (используется whisper_live_manage)
├── .rest_port            # Активный порт REST API (используется whisper_live_manage)
├── .model                # Активное имя модели (используется whisper_live_manage)
└── .server_addr          # Кэшированный IP сервера (используется whisper_live_manage)
```

Загруженные модели сохраняются в томе `whisper-live-data`. Создавайте резервные копии Docker-тома для сохранения загруженных моделей. Модели занимают от 145 МБ до 3 ГБ и могут загружаться несколько минут при первом подключении клиента; сохранение тома позволяет избежать повторной загрузки при пересоздании контейнера.

**Совет:** Том `/var/lib/whisper-live` использует ту же схему кэша HuggingFace, что и том `/var/lib/whisper` проекта ScribeCrate. Если вы уже скачали модель с помощью ScribeCrate, можно примонтировать тот же каталог тома, чтобы избежать повторной загрузки.

## Управление сервером

```bash
docker exec whisper-live whisper_live_manage --showinfo
docker exec whisper-live whisper_live_manage --listmodels
docker exec whisper-live whisper_live_manage --downloadmodel large-v3-turbo
```

## Смена модели

1. *(Опционально, но рекомендуется)* Предварительно скачайте новую модель:
   ```bash
   docker exec whisper-live whisper_live_manage --downloadmodel large-v3-turbo
   ```
2. Обновите `WHISPERLIVE_MODEL` в файле `whisper-live.env`.
3. Перезапустите контейнер:
   ```bash
   docker restart whisper-live
   ```

**Доступные модели:**

| Модель | Диск | ОЗУ (примерно) | Примечания |
|---|---|---|---|
| `tiny` | ~75 МБ | ~250 МБ | Самая быстрая; низкая точность |
| `tiny.en` | ~75 МБ | ~250 МБ | Только английский |
| `base` | ~145 МБ | ~700 МБ | Хороший баланс — **по умолчанию** |
| `base.en` | ~145 МБ | ~700 МБ | Только английский |
| `small` | ~465 МБ | ~1,5 ГБ | Повышенная точность |
| `small.en` | ~465 МБ | ~1,5 ГБ | Только английский |
| `medium` | ~1,5 ГБ | ~5 ГБ | Высокая точность |
| `medium.en` | ~1,5 ГБ | ~5 ГБ | Только английский |
| `large-v1` | ~3 ГБ | ~10 ГБ | Старая большая модель |
| `large-v2` | ~3 ГБ | ~10 ГБ | Очень высокая точность |
| `large-v3` | ~3 ГБ | ~10 ГБ | Наивысшая точность |
| `large-v3-turbo` | ~1,6 ГБ | ~6 ГБ | Быстрая + высокая точность ⭐ |
| `turbo` | ~1,6 ГБ | ~6 ГБ | Псевдоним для `large-v3-turbo` |

> **Совет:** `large-v3-turbo` обеспечивает точность, близкую к `large-v3`, при вдвое меньшем потреблении ресурсов. Для большинства производственных развёртываний это рекомендуемый вариант обновления с `base`.

Данные по памяти являются приблизительными и учитывают квантование INT8 (по умолчанию). Модели кэшируются в Docker-томе `/var/lib/whisper-live` и загружаются только один раз.

## Защита сервера

Если ваш сервер ScribeCrate Live доступен из публичной сети — даже кратковременно — примените как минимум следующие меры защиты. ScribeCrate Live требует значительных ресурсов CPU/GPU, поэтому незащищённая конечная точка может быть использована для расходования ваших вычислительных ресурсов.

**1. Используйте API-ключ.** Новые установки с подключённым томом `/var/lib/whisper-live` автоматически генерируют API-ключ. Его можно посмотреть командой `docker exec whisper-live whisper_live_manage --showkey`; в скриптах используйте `docker exec whisper-live whisper_live_manage --getkey`. Существующие установки без ключа остаются открытыми для обратной совместимости; также можно задать `WHISPERLIVE_API_KEY` в env-файле вручную. REST-клиенты транскрипции должны отправлять `Authorization: Bearer <key>`; WebSocket-клиенты могут отправлять тот же заголовок или добавить `?token=<key>` к URL.

**2. Привяжите к localhost при использовании обратного прокси.** Замените `-p 9090:9090 -p 8000:8000` на `-p 127.0.0.1:9090:9090 -p 127.0.0.1:8000:8000` (или измените оба маппинга портов на их эквиваленты с `127.0.0.1:` в `docker-compose.yml`), чтобы незашифрованные порты нельзя было достичь напрямую снаружи хоста.

**3. Ограничьте размер загружаемых файлов на прокси.** Аудиофайлы могут быть большими; настройте обратный прокси на отклонение слишком больших загрузок (например, nginx `client_max_body_size 100M;`). Это ограничивает занимаемые одним запросом ресурсы диска и памяти.

**4. Следите за уровнем журналирования.** При `WHISPERLIVE_LOG_LEVEL=DEBUG` текст транскрипции может попадать в журналы. На общих системах сохраняйте уровень `INFO` или выше.

**5. Ограничьте источники WebSocket на прокси.** WebSocket-соединения из ненадёжных браузерных источников можно заблокировать на уровне обратного прокси. Для nginx проверяйте `$http_origin` перед апгрейдом соединения; для Caddy используйте директиву `header` для проверки заголовка `Origin`.

**6. Рассмотрите ограничение частоты запросов.** Разместите перед сервером ограничитель частоты (например, nginx `limit_req_zone`, Caddy `rate_limit`), чтобы ограничить количество одновременных запросов транскрипции на один IP-адрес клиента.

## Использование обратного прокси

Используйте один из следующих адресов для доступа к контейнеру из обратного прокси:

- **`whisper-live:9090`** / **`whisper-live:8000`** — если обратный прокси работает как контейнер в **той же Docker-сети**.
- **`127.0.0.1:9090`** / **`127.0.0.1:8000`** — если обратный прокси работает **на хосте** и порты опубликованы.

**Пример с [Caddy](https://caddyserver.com/docs/) ([Docker-образ](https://hub.docker.com/_/caddy))** (автоматический TLS, проксирование WebSocket в той же Docker-сети):

`Caddyfile`:
```
whisper-live.example.com {
  # WebSocket-поток (wss://)
  handle /ws* {
    reverse_proxy whisper-live:9090
  }
  # REST API (https://)
  reverse_proxy whisper-live:8000
}
```

**Пример с nginx** (обратный прокси на хосте):

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

    # WebSocket-поток
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
> Для проксирования WebSocket необходимы `proxy_http_version 1.1` и заголовки `Upgrade`/`Connection`. Без них потоковая передача в реальном времени через nginx работать не будет.

<details>
<summary><strong>Добавление дополнительной аутентификации на уровне прокси</strong></summary>

Сервер поддерживает встроенную аутентификацию по API-ключу через `WHISPERLIVE_API_KEY`. Для развёртываний с доступом из интернета можно дополнительно добавить Bearer-токен или базовую аутентификацию на уровне обратного прокси. Пример с Caddy (`basicauth` защищает REST API):

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

Пример с nginx (`auth_basic` на location REST API):

```nginx
location /v1/ {
    auth_basic           "WhisperLive";
    auth_basic_user_file /etc/nginx/.htpasswd;
    proxy_pass           http://127.0.0.1:8000;
    proxy_set_header     Host $host;
    proxy_read_timeout   300s;
}
```

WebSocket-клиенты вне браузера могут использовать заголовок `Authorization` для аутентификации. Поскольку браузерный WebSocket API не позволяет задавать произвольные заголовки, браузерные клиенты могут использовать `?token=<key>`. Для дополнительной защиты привяжите порт `9090` к `127.0.0.1` и разместите его за обратным прокси.

</details>

## Обновление Docker-образа

```bash
docker pull hwdsl2/whisper-live-server
docker rm -f whisper-live
# Затем повторно выполните команду docker run из раздела «Быстрый старт» с теми же томами и портами.
```

Загруженные модели сохраняются в томе `whisper-live-data`.

## Использование с другими AI-сервисами

ScribeCrate Live можно использовать как службу распознавания речи в реальном времени в более широком self-hosted AI-стеке.

Готовые полные и облегчённые стеки Docker Compose, примеры ручного запуска через `docker run`, а также примеры голосовых, RAG- и MCP-конвейеров с SpeakCrate, EmbedCrate, GatewayCrate, InferCrate, ParseCrate и UplinkCrate см. в [Self-Hosted AI Stack](https://github.com/hwdsl2/self-hosted-ai-stack/blob/main/README-ru.md).

## Счётчики использования

Этот образ использует публичные счётчики скачиваний GitHub Release assets для анонимной агрегированной статистики использования. Эти числа приблизительны и не являются количеством уникальных пользователей или активных установок. Образ не отправляет telemetry payload и не использует частный сборщик. Он выполняет только best-effort запрос после успешного запуска сервера с подключённым томом `/var/lib/whisper-live`, а также при первом запуске другой сборки образа для этой постоянной установки. Чтобы отключить это, задайте `WHISPERLIVE_DISABLE_USAGE_COUNTS=1`.

## Техническая информация

- Базовый образ: `python:3.12-slim` (Debian)
- Среда выполнения: Python 3 (виртуальное окружение в `/opt/venv`)
- STT-движок: [WhisperLive](https://github.com/collabora/WhisperLive) + [faster-whisper](https://github.com/SYSTRAN/faster-whisper) с CTranslate2 (INT8 на CPU, FP16 на CUDA)
- VAD: [Silero VAD](https://github.com/snakers4/silero-vad) через PyTorch (CPU или CUDA, определяется автоматически)
- WebSocket-сервер: библиотека Python `websockets`
- REST API: [FastAPI](https://fastapi.tiangolo.com/) + [Uvicorn](https://www.uvicorn.org/)
- Директория данных: `/var/lib/whisper-live` (Docker-том)
- Хранение моделей: формат HuggingFace Hub внутри тома — загружается один раз, переиспользуется при перезапусках

## Лицензия

**Примечание:** Программные компоненты внутри готового образа (такие как WhisperLive, faster-whisper, PyTorch и их зависимости) распространяются под соответствующими лицензиями, выбранными их правообладателями. При использовании готового образа пользователь несёт ответственность за соблюдение всех применимых лицензий.

Copyright (C) 2026 Lin Song   
Данная работа распространяется под [лицензией MIT](https://opensource.org/licenses/MIT).

**WhisperLive** является собственностью Vineet Suryan, Collabora Ltd. и распространяется под [лицензией MIT](https://github.com/collabora/WhisperLive/blob/main/LICENSE).

**faster-whisper** является собственностью SYSTRAN и распространяется под [лицензией MIT](https://github.com/SYSTRAN/faster-whisper/blob/master/LICENSE).

Данный проект является независимой Docker-обёрткой и не связан с OpenAI, Collabora или SYSTRAN, не одобрен и не спонсируется ими.
