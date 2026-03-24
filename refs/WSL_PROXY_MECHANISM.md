# OpenClaw 在 WSL 中的自动代理机制说明

> 适用环境：OpenClaw 运行在 WSL2，代理软件运行在 Windows 主机（Clash/Clash Verge/V2RayN/sing-box 等）。

## 结论

自动代理机制不是 OpenClaw 默认内建逻辑，而是通过一次性安装脚本把“代理刷新流程”注入到 systemd 服务启动链里实现的。

安装后，只要 `openclaw-gateway.service` 通过 systemd 启动/重启，都会自动刷新并注入代理环境变量。

---

## 机制组成（3 个关键文件）

1. 代理刷新脚本
   - `~/.local/bin/openclaw-refresh-proxy.sh`

2. systemd override
   - `~/.config/systemd/user/openclaw-gateway.service.d/proxy.conf`
   - 关键配置：
     - `ExecStartPre=%h/.local/bin/openclaw-refresh-proxy.sh`
     - `EnvironmentFile=%h/.openclaw/openclaw-proxy.env`

3. 代理环境文件
   - `~/.openclaw/openclaw-proxy.env`
   - 示例变量：`HTTP_PROXY` / `HTTPS_PROXY` / `NO_PROXY`

---

## 启动时序（简版）

systemd 启动 `openclaw-gateway.service`
→ 执行 `ExecStartPre` 代理刷新脚本
→ 脚本探测 Windows IP 与可用代理端口
→ 写入 `~/.openclaw/openclaw-proxy.env`
→ Gateway 进程通过 `EnvironmentFile` 读取代理变量启动

---

## 如何验证“当前是否在走自动代理”

### 1) 看 env 文件

```bash
cat ~/.openclaw/openclaw-proxy.env
```

### 2) 看 systemd 是否挂载了 override

```bash
systemctl --user cat openclaw-gateway.service
```

确认存在：
- `EnvironmentFile=%h/.openclaw/openclaw-proxy.env`
- `ExecStartPre=%h/.local/bin/openclaw-refresh-proxy.sh`

### 3) 看运行中进程环境变量

```bash
pid=$(systemctl --user show -p MainPID --value openclaw-gateway.service)
tr '\0' '\n' < /proc/$pid/environ | grep -Ei '^(http|https|no)_proxy='
```

---

## 边界与注意事项

- 若绕过 systemd，手动直接执行 `node ... gateway`，则不保证自动注入代理。
- 若 Windows 代理端口变化/关闭，脚本探测可能失败，需要检查代理软件和防火墙。
- 推荐保留 loopback 绑定并开启网关鉴权（`gateway.auth.mode=token`）。

---

## 快速自检命令

```bash
openclaw gateway status
openclaw status
journalctl --user -u openclaw-gateway.service -n 120 --no-pager
```
