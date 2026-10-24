# Changelog

Notable changes to ScribeCrate Live are documented here.

## 2026-10-24

Release: `2026.10.1`

### Changed

- Established the first tagged source release. Docker images continue to update
  independently through existing moving tags.

## 2026-10-15

### Changed

- Integrated WhisperLive 0.10.0 and its upstream WebSocket authentication.
  REST transcription requires a Bearer key when authentication is enabled;
  `/docs`, `/redoc`, `/openapi.json`, and `/health` are now public.

## 2026-10-08

### Fixed

- Restored audio-decoding compatibility by excluding PyAV 19, which removed
  an option still used by faster-whisper.

## 2026-10-07

### Changed

- Rebranded as ScribeCrate Live (formerly `docker-whisper-live`); the Docker
  image name remains `hwdsl2/whisper-live-server`.

## 2026-08-05

### Fixed

- Fixed WebSocket API-key validation with newer versions of the websockets
  library, including rejection of clients with missing or invalid keys.

## 2026-07-09

### Added

- Added anonymous aggregate deployment/upgrade counts. Opt out with
  `WHISPERLIVE_DISABLE_USAGE_COUNTS=1`.

## 2026-06-20

### Added

- Added API-key configuration and automatic key generation for fresh installs
  with persistent storage. Retrieve the key with
  `whisper_live_manage --getkey`. Existing volumes without a key retain their
  previous authentication behavior.

## Earlier notable changes

- Added real-time WebSocket transcription and an OpenAI-compatible REST API
  for audio-file transcription.
- Added NVIDIA CUDA images, persistent model caching, and management commands
  for model downloads and server information.
