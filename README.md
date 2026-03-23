# oc-wsl-clash-proxy

> Make OpenClaw in **WSL2** follow your **Windows proxy stack** automatically (Clash / Clash Verge / V2RayN / sing-box), with pre-start refresh for stable long-running service.

[中文](#中文) | [English](#english)

---

## 中文

让 OpenClaw 在 **WSL2** 中自动跟随 Windows 主机代理，不再手动改 IP、改端口、改环境变量。  
尤其适合国内网络环境下的长期常驻（systemd）场景。

### 它解决了什么问题

- WSL 每次重启后 Windows 网关 IP 可能变化（`172.x.x.1` 漂移）
- 代理端口可能变化（不同软件/模式端口不一致）
- 服务重启后经常“看起来断线”或启动失败
- 手工维护 `HTTP(S)_PROXY` 容易出错

### 为什么值得用

- **自动跟随**：自动探测 Windows 主机 IP + 常见代理端口
- **稳定启动**：在 gateway 启动前执行刷新，降低冷启动失败率
- **保留分流策略**：WSL 请求走 Windows 代理，分流逻辑由你的代理软件统一处理
- **可回退**：支持 `PROXY_URL` 固定地址，排障时一键切换

### 先决条件（重要）

- Windows 代理软件需开启 **Allow LAN / 允许局域网连接**，否则 WSL 可能无法连到代理端口

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

Run OpenClaw in **WSL2** while automatically following your Windows-hosted proxy setup.  
No more manual IP/port/env updates after reboot.

### What it solves

- Windows host gateway IP in WSL can change after reboot/network switch
- Proxy ports differ across apps/modes
- Gateway restart can fail when proxy target drifts
- Manual `HTTP(S)_PROXY` maintenance is error-prone

### Why use this

- **Auto-follow host proxy**: detect Windows host IP + common proxy ports
- **Stable startup**: refresh before gateway start (`ExecStartPre`)
- **Keep your routing rules**: traffic goes through your Windows proxy app, so existing split-routing rules still apply
- **Debug-friendly**: override with fixed `PROXY_URL` when needed

### Prerequisite (important)

- Enable **Allow LAN / local network access** in your Windows proxy app, otherwise WSL may fail to reach the proxy port

### Quick Start

```bash
bash skills/oc-wsl-clash-proxy/scripts/enable_wsl_clash_proxy_service.sh
```

### Optional Parameters

- `PROXY_URL`: fixed proxy URL (highest priority), e.g. `http://<WINDOWS_HOST_IP>:7890`
- `CLASH_PORT`: single preferred port (legacy-compatible)
- `PROXY_PORTS`: comma-separated candidate ports
- `SERVICE_NAME`: default `openclaw-gateway.service`

### Verify

```bash
openclaw gateway status
systemctl --user status openclaw-gateway.service --no-pager
journalctl --user -u openclaw-gateway.service -n 120 --no-pager
```

---

## Notes

- Scope: **WSL native + systemd** workflow
- Docker / OnePanel deployments should use dedicated adaptation
- Please comply with local laws and third-party ToS/AUP

## License

MIT (or repository default)
