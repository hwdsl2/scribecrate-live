#
# Copyright (C) 2026 Lin Song <linsongui@gmail.com>
#
# This work is licensed under the MIT License
# See: https://opensource.org/licenses/MIT

FROM python:3.12-slim

WORKDIR /opt/src

ARG WHISPERLIVE_VERSION=0.10.0
ARG WEBSOCKETS_VERSION=17.1

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PATH="/opt/venv/bin:$PATH"

# PyAV 19 removed metadata_errors, which faster-whisper's decoder still uses.
RUN set -x \
    && apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl gcc libc6-dev portaudio19-dev \
    && python3 -m venv /opt/venv \
    && pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir torch --index-url https://download.pytorch.org/whl/cpu \
    && pip install --no-cache-dir --uploaded-prior-to P7D \
         "whisper-live==$WHISPERLIVE_VERSION" \
         "websockets==$WEBSOCKETS_VERSION" \
         faster-whisper \
         "av>=11,<19" \
         fastapi \
         uvicorn \
         python-multipart \
    && site_dir=$(python -c 'import site; print(site.getsitepackages()[0])') \
    && WHISPERLIVE_VERSION="$WHISPERLIVE_VERSION" WEBSOCKETS_VERSION="$WEBSOCKETS_VERSION" \
         python -c 'import os; from importlib.metadata import version; assert version("whisper-live") == os.environ["WHISPERLIVE_VERSION"]; assert version("websockets") == os.environ["WEBSOCKETS_VERSION"]' \
    && python -m py_compile "$site_dir/whisper_live/server.py" \
    && pip list --format=freeze | grep -iE '^nvidia[_-]|^cuda[_-]|^triton' | cut -d= -f1 | xargs -r pip uninstall -y \
    && apt-get purge -y --auto-remove gcc libc6-dev \
    && rm -rf /var/lib/apt/lists/* \
    && python -c 'import torch; assert torch.version.cuda is None, torch.__version__; from whisper_live.server import TranscriptionServer' \
    && find /opt/venv -name '*.pyi' -delete \
    && { find /opt/venv -type d -name '__pycache__' -exec rm -rf {} + 2>/dev/null || true; } \
    && mkdir -p /var/lib/whisper-live

COPY ./run.sh /opt/src/run.sh
COPY ./manage.sh /opt/src/manage.sh
COPY ./LICENSE.md /opt/src/LICENSE.md
RUN chmod 755 /opt/src/run.sh /opt/src/manage.sh \
    && ln -s /opt/src/manage.sh /usr/local/bin/whisper_live_manage

EXPOSE 9090/tcp
EXPOSE 8000/tcp
VOLUME ["/var/lib/whisper-live"]
CMD ["/opt/src/run.sh"]

ARG BUILD_DATE
ARG VERSION
ARG VCS_REF
ENV IMAGE_VER=$BUILD_DATE
ENV IMAGE_FLAVOR=$VERSION

LABEL maintainer="Lin Song <linsongui@gmail.com>" \
    org.opencontainers.image.created="$BUILD_DATE" \
    org.opencontainers.image.version="$VERSION" \
    org.opencontainers.image.revision="$VCS_REF" \
    org.opencontainers.image.authors="Lin Song <linsongui@gmail.com>" \
    org.opencontainers.image.title="ScribeCrate Live" \
    org.opencontainers.image.description="ScribeCrate Live: self-hosted real-time transcription powered by WhisperLive and faster-whisper, with WebSocket streaming and an OpenAI-compatible REST API for audio files." \
    org.opencontainers.image.url="https://github.com/hwdsl2/scribecrate-live" \
    org.opencontainers.image.source="https://github.com/hwdsl2/scribecrate-live" \
    org.opencontainers.image.documentation="https://github.com/hwdsl2/scribecrate-live"
