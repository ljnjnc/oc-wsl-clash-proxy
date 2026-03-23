---
name: oc-wsl-clash-proxy
description: Configure OpenClaw in WSL to auto-use a Windows host proxy (Clash/Clash Verge/V2RayN/Sing-box etc.) for reliable API access and resident gateway startup. Use when users mention WSL + OpenClaw + proxy instability, China network issues, "自动探测 Windows IP", or "每次启动自动代理".
---

# OC WSL Clash Proxy

面向场景：
- OpenClaw 运行在 **WSL2**
- 代理软件运行在 **Windows 主机**
- 需要 OpenClaw 常驻（systemd）且每次启动自动刷新代理

> 该 Skill 是 **WSL 原生部署** 方案，不是 Docker/OnePanel 方案。

## What this skill does

- 自动探测 Windows 主机 IP（`/etc/resolv.conf`，失败时回退默认路由）
- 自动探测可用代理端口（不绑定单一软件）
  - 默认候选：`7897,7890,20171,10809,10808,8080,3128,8118`
  - 可通过 `PROXY_PORTS` 自定义
- 支持固定代理地址覆盖：`PROXY_URL=http://x.x.x.x:port`
- 写入代理环境文件：`~/.openclaw/openclaw-proxy.env`
- 安装刷新脚本：`~/.local/bin/openclaw-refresh-proxy.sh`
- 配置 `openclaw-gateway.service` 的 systemd override：
  - `EnvironmentFile=%h/.openclaw/openclaw-proxy.env`
  - `ExecStartPre=%h/.local/bin/openclaw-refresh-proxy.sh`
- 自动 `daemon-reload + enable + restart`，让服务每次启动前动态刷新代理

## Run

```bash
bash skills/oc-wsl-clash-proxy/scripts/enable_wsl_clash_proxy_service.sh
```

可选环境变量：

- `PROXY_URL`：固定代理 URL（最高优先级）
- `CLASH_PORT`：单一优先端口（兼容旧参数）
- `PROXY_PORTS`：自动探测端口列表（逗号分隔）
- `SERVICE_NAME`：默认 `openclaw-gateway.service`

示例：

```bash
# 全自动（推荐）
bash skills/oc-wsl-clash-proxy/scripts/enable_wsl_clash_proxy_service.sh

# 固定代理地址
PROXY_URL=http://172.21.208.1:7890 bash skills/oc-wsl-clash-proxy/scripts/enable_wsl_clash_proxy_service.sh

# 自定义端口探测顺序
PROXY_PORTS=7897,7890,20171,9090 bash skills/oc-wsl-clash-proxy/scripts/enable_wsl_clash_proxy_service.sh
```

## Validation checklist

```bash
openclaw gateway status
systemctl --user status openclaw-gateway.service --no-pager
journalctl --user -u openclaw-gateway.service -n 120 --no-pager
```

预期：
- service 为 `enabled` + `active (running)`
- `ExecStartPre=...openclaw-refresh-proxy.sh` 为 `SUCCESS`

## Troubleshooting quick checks

1. Windows 代理软件是否运行
2. 是否开启 `Allow LAN / 局域网连接`
3. 端口是否变化（7890/7897/20171 等）
4. Windows 防火墙是否拦截代理端口
5. 服务重启后是否成功刷新 env 文件：`~/.openclaw/openclaw-proxy.env`

## Boundaries / Non-goals

- 不提供代理节点、订阅、绕过策略
- 不负责修改用户代理软件配置，仅做连通性检测与注入
- 不覆盖 Docker/OnePanel（应使用专门的 Docker 版 skill）

## Compliance notes (publish-safe)

- 本 Skill 仅用于合法合规的网络连通性与稳定性优化
- 用户需自行遵守所在地法律法规及第三方服务条款（ToS/AUP）
- 日志排障时应脱敏 Token/密钥/Cookie 等敏感信息
