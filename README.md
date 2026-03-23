# oc-wsl-clash-proxy

> Auto-configure OpenClaw in **WSL2** to use your **Windows host proxy** (Clash / Clash Verge / V2RayN / sing-box), with systemd pre-start refresh for stable startup.

[中文](#中文) | [English](#english)

---

## 中文

让 OpenClaw 在 **WSL2** 下自动使用 Windows 主机代理，并在服务启动前动态刷新代理配置，提升连通性与稳定性。

### 适用场景

- OpenClaw 运行在 WSL2
- 代理软件运行在 Windows 主机
- 需要 systemd 常驻稳定启动
- 需要自动应对 Windows IP / 端口变化

### 功能特性

- 自动探测 Windows 主机 IP（`/etc/resolv.conf` + route fallback）
- 自动探测常见代理端口（可自定义）
- 支持固定代理覆盖：`PROXY_URL`
- 自动写入：`~/.openclaw/openclaw-proxy.env`
- 注入 `openclaw-gateway.service` 的 `ExecStartPre` 刷新钩子

### 快速开始

```bash
bash skills/oc-wsl-clash-proxy/scripts/enable_wsl_clash_proxy_service.sh
```

### 可选参数

- `PROXY_URL`：固定代理 URL（最高优先级），例如 `http://<WINDOWS_HOST_IP>:7890`
- `CLASH_PORT`：单一优先端口（兼容旧参数）
- `PROXY_PORTS`：候选端口列表（逗号分隔）
- `SERVICE_NAME`：默认 `openclaw-gateway.service`

> 说明：WSL2 下 Windows 主机 IP（常见 `172.x.x.1`）可能随重启/网络变化而变化，通常不建议写死，优先自动探测。

### 验证

```bash
openclaw gateway status
systemctl --user status openclaw-gateway.service --no-pager
journalctl --user -u openclaw-gateway.service -n 120 --no-pager
```

---

## English

Make OpenClaw running in **WSL2** automatically use your Windows-hosted proxy, and refresh proxy settings before service startup for better reliability.

### Use Cases

- OpenClaw runs in WSL2
- Proxy app runs on Windows host
- You want stable systemd-based resident service
- You need automatic handling for changing host IP / ports

### Features

- Auto-detect Windows host IP (`/etc/resolv.conf` + route fallback)
- Auto-detect common proxy ports (customizable)
- Support fixed override via `PROXY_URL`
- Refresh `~/.openclaw/openclaw-proxy.env` automatically
- Inject pre-start refresh hook into `openclaw-gateway.service`

### Quick Start

```bash
bash skills/oc-wsl-clash-proxy/scripts/enable_wsl_clash_proxy_service.sh
```

### Optional Parameters

- `PROXY_URL`: fixed proxy URL (highest priority), e.g. `http://<WINDOWS_HOST_IP>:7890`
- `CLASH_PORT`: single preferred port (legacy-compatible)
- `PROXY_PORTS`: comma-separated candidate ports
- `SERVICE_NAME`: default `openclaw-gateway.service`

### Verification

```bash
openclaw gateway status
systemctl --user status openclaw-gateway.service --no-pager
journalctl --user -u openclaw-gateway.service -n 120 --no-pager
```

---

## Notes

- This project focuses on **WSL native + systemd** workflow.
- For Docker / OnePanel, use a dedicated adaptation.
- Please comply with local laws and third-party ToS/AUP.

## License

MIT (or repository default)
