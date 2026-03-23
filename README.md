# oc-wsl-clash-proxy

> **让 OpenClaw 在 WSL2 自动跟随 Windows 代理分流策略。**  
> One command to keep WSL proxy in sync with your Windows host (Clash / Clash Verge / V2RayN / sing-box).

[中文](#中文) | [English](#english)

---

## 中文

### 这是干什么的？

`oc-wsl-clash-proxy` 专门解决一个高频痛点：

> OpenClaw 跑在 WSL，代理跑在 Windows。  
> 重启后 IP 变了、端口变了、服务就断了。

这个项目会在 gateway 启动前自动刷新代理配置，让 WSL 始终跟随 Windows 主机代理，尽量不手工修配置。

### 你会得到什么

- ✅ **自动探测 Windows 主机 IP**（避免 `172.x.x.1` 写死后失效）
- ✅ **自动探测代理端口**（适配不同代理软件与模式）
- ✅ **保留你现有分流规则**（规则继续由 Windows 代理软件统一处理）
- ✅ **systemd 常驻友好**（`ExecStartPre` 启动前刷新）
- ✅ **可排障回退**（支持 `PROXY_URL` 固定覆盖）

### 适合谁用

- OpenClaw 在 WSL2 运行
- Clash/Clash Verge/V2RayN/sing-box 在 Windows 运行
- 追求“常驻稳定 + 少人工干预”

### 先决条件（重要）

- Windows 代理软件必须开启 **Allow LAN / 允许局域网连接**，否则 WSL 无法访问代理端口

### Clash Verge 示例（Allow LAN）

按这个顺序检查：

1. 打开 Clash Verge → **Settings / General**
2. 找到 **Allow LAN / 允许局域网连接**
3. 确保开关为 **ON**

![Clash Verge - Allow LAN 示例（中文界面）](assets/screenshots/clash-verge-allow-lan-zh.jpg)

> 关键开关位置：右侧设置区域中的 **Allow LAN / 允许局域网连接**，请保持 **ON**。

### 30 秒开始

```bash
bash skills/oc-wsl-clash-proxy/scripts/enable_wsl_clash_proxy_service.sh
```

### 可选参数

- `PROXY_URL`：固定代理 URL（最高优先级），例：`http://<WINDOWS_HOST_IP>:7890`
- `CLASH_PORT`：单端口优先（兼容旧参数）
- `PROXY_PORTS`：候选端口列表（逗号分隔）
- `SERVICE_NAME`：默认 `openclaw-gateway.service`

> 建议：默认走自动探测；仅在排障时使用固定 `PROXY_URL`。

### 验证

```bash
openclaw gateway status
systemctl --user status openclaw-gateway.service --no-pager
journalctl --user -u openclaw-gateway.service -n 120 --no-pager
```

### 常见收益（真实体验）

- 减少“重启后突然不可用”
- 减少手工改环境变量和 IP 的操作
- 降低代理抖动带来的误判与排障时间

---

## English

### What is this?

`oc-wsl-clash-proxy` fixes a common setup pain:

> OpenClaw runs in WSL, proxy runs on Windows.  
> After reboot, host IP/port drifts, and the service breaks.

This project refreshes proxy settings before gateway startup, so WSL keeps following your Windows proxy setup automatically.

### Real pain points this targets

- Many top-tier overseas model APIs can be unreachable, or reachable but very slow
- Large downloads can take hours and often fail midway
- API calls may randomly disconnect/timeout, breaking long-running workflows

> This project was built from those exact frustrations: reduce manual firefighting, improve reachability and stability first.

### What you get

- ✅ **Auto-detect Windows host IP** (no fragile hardcoded `172.x.x.1`)
- ✅ **Auto-detect proxy ports** (works across proxy apps/modes)
- ✅ **Keep your split-routing behavior** (routing rules stay in your Windows proxy app)
- ✅ **Systemd-ready startup flow** (`ExecStartPre` refresh)
- ✅ **Debug fallback** with fixed `PROXY_URL`

### Who should use this

- OpenClaw runs in WSL2
- Proxy app runs on Windows
- You want stable long-running service with minimal manual maintenance

### Prerequisite (important)

- Enable **Allow LAN / local network access** in your Windows proxy app, otherwise WSL cannot reach the proxy port

### Clash Verge example (Allow LAN)

Checklist:

1. Open Clash Verge → **Settings / General**
2. Find **Allow LAN / local network access**
3. Make sure the toggle is **ON**

![Clash Verge - Allow LAN example (English UI)](assets/screenshots/clash-verge-allow-lan-en.jpg)

> Key toggle location: **Allow LAN / local network access** in the right settings panel, keep it **ON**.

### Quick Start

```bash
bash skills/oc-wsl-clash-proxy/scripts/enable_wsl_clash_proxy_service.sh
```

### Optional parameters

- `PROXY_URL`: fixed proxy URL (highest priority), e.g. `http://<WINDOWS_HOST_IP>:7890`
- `CLASH_PORT`: preferred single port (legacy-compatible)
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
