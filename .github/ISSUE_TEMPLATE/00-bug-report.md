---
name: Bug report
about: Tell us about a problem you are experiencing
title: ''
labels: ''
assignees: ''

---
**Checklist**

- [ ] I read the [README](https://github.com/hwdsl2/scribecrate-live/blob/main/README.md) or the relevant section
- [ ] I searched existing [Issues](https://github.com/hwdsl2/scribecrate-live/issues?q=is%3Aissue)
- [ ] This issue is about the ScribeCrate Live Docker image/config/API, not only WhisperLive or faster-whisper itself

<!---
If this is a bug in WhisperLive WebSocket/server behavior, it may belong in https://github.com/collabora/WhisperLive. If it is about model loading or transcription output, it may belong in https://github.com/SYSTRAN/faster-whisper.
--->

**Describe the issue**
A clear and concise description of the problem.

**Deployment context**
- [ ] Standalone container
- [ ] Part of [self-hosted-ai-stack](https://github.com/hwdsl2/self-hosted-ai-stack)

**To Reproduce**
Steps to reproduce the behavior:

1. ...
2. ...

**Expected behavior**
A clear and concise description of what you expected to happen.

**Environment**
- Docker host OS: [e.g. Ubuntu 24.04]
- Hosting provider (if applicable): [e.g. AWS, GCP, home server]
- CPU architecture: [e.g. amd64, arm64]
- Image/tag: [e.g. `hwdsl2/whisper-live-server:latest`]
- Start method: [docker run / docker compose / other]
- Published port(s): [9090 WebSocket, 8000 REST]

**Configuration**
Remove secrets, API keys, tokens and private URLs before posting.

- Env file or variables changed: [whisper-live.env / `-e` / compose `environment`]
- Docker run or compose changes:

**Service details**
- Interface involved: WebSocket, REST API, or both:
- WebSocket client/protocol details or REST request parameters:
- Active model and `WHISPERLIVE_*` settings:
- VAD, max clients, connection time, proxy/auth, or WebSocket origin settings, if relevant:
- Management command output, if relevant (for example `docker exec whisper-live whisper_live_manage --showinfo`):
- GPU/CUDA image tag and NVIDIA driver/toolkit versions, if relevant:

**Logs**
Add relevant logs with secrets removed.

```bash
docker logs whisper-live
```

If using Docker Compose, you can also include:

```bash
docker compose logs whisper-live
```

**Additional context**
Add any other context about the problem here.
