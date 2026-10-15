---
name: 错误报告
about: 请使用这个模板来提交 bug
title: ''
labels: ''
assignees: ''

---
**任务列表**

- [ ] 我已阅读[自述文件](https://github.com/hwdsl2/scribecrate-live/blob/main/README-zh.md)或相关章节
- [ ] 我搜索了已有的 [Issues](https://github.com/hwdsl2/scribecrate-live/issues?q=is%3Aissue)
- [ ] 这个问题是关于 ScribeCrate Live Docker 镜像/配置/API，而不只是 WhisperLive 或 faster-whisper 本身

<!---
如果你确认问题属于上游项目本身，请考虑在相应上游项目提交 issue：[WhisperLive](https://github.com/collabora/WhisperLive), [faster-whisper](https://github.com/SYSTRAN/faster-whisper)。
--->

**问题描述**
使用清楚简明的语言描述这个问题。

**部署场景**
- [ ] 独立容器
- [ ] 属于 [self-hosted-ai-stack](https://github.com/hwdsl2/self-hosted-ai-stack/blob/main/README-zh.md)

**重现步骤**
重现该问题的步骤：

1. ...
2. ...

**期待的正确结果**
简要描述你期望发生的结果。

**环境**
- Docker 主机操作系统: [例如 Ubuntu 24.04]
- 服务提供商（如果适用）: [例如 AWS, GCP, 家用服务器]
- CPU 架构: [例如 amd64, arm64]
- 镜像/标签: [例如 `hwdsl2/whisper-live-server:latest`]
- 启动方式: [docker run / docker compose / 其它]
- 发布的端口: [9090 WebSocket, 8000 REST]

**配置**
发布前请删除 secrets、API keys、tokens 和私有 URL。

- 修改过的 env 文件或变量: [whisper-live.env / `-e` / compose `environment`]
- Docker run 或 compose 修改：

**服务细节**
- 涉及的接口：WebSocket、REST API 或两者：
- WebSocket 客户端/协议细节或 REST 请求参数：
- 当前模型和 `WHISPERLIVE_*` 设置：
- VAD、最大客户端数、连接时长、代理/认证或 WebSocket Origin 设置（如果相关）：
- 相关管理命令输出（例如 `docker exec whisper-live whisper_live_manage --showinfo`）：
- GPU/CUDA 镜像标签和 NVIDIA driver/toolkit 版本（如果相关）：

**日志**
请添加相关日志，并删除敏感信息。

```bash
docker logs whisper-live
```

如果使用 Docker Compose，也可以包含：

```bash
docker compose logs whisper-live
```

**其它信息**
添加关于该问题的其它信息。
