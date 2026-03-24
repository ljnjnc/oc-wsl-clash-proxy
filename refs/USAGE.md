# 使用指南（给拿来就用的人）

> 目标：不依赖 `oc` 别名，只用标准命令，5 分钟内跑通。  
> 适用：OpenClaw 在 WSL2，代理在 Windows 主机。

---

## 0) 前置条件

- 已安装 OpenClaw（可执行 `openclaw --version`）
- Windows 代理工具已开启 **Allow LAN / 允许局域网连接**
- 以与 OpenClaw Gateway 相同的 Linux 用户执行（通常是当前用户）

---

## 1) 安装（推荐目录）

```bash
mkdir -p ~/.openclaw/workspace/skills
cd ~/.openclaw/workspace/skills
git clone https://github.com/ljnjnc/oc-wsl-clash-proxy.git
cd oc-wsl-clash-proxy
```

> 推荐路径：`~/.openclaw/workspace/skills/oc-wsl-clash-proxy`

---

## 2) 启用自动代理机制

```bash
bash scripts/enable_wsl_clash_proxy_service.sh
```

这一步会：
- 安装刷新脚本 `~/.local/bin/openclaw-refresh-proxy.sh`
- 写入 systemd drop-in：`~/.config/systemd/user/openclaw-gateway.service.d/proxy.conf`
- 生成代理环境文件：`~/.openclaw/openclaw-proxy.env`
- 重启并启用 gateway 服务

---

## 3) 一键验收（推荐）

```bash
bash scripts/oc-check.sh
```

看到 `OK: service is running and proxy variables are injected.` 即为通过。

---

## 4) 日常使用（不要依赖 oc）

```bash
# 重启
openclaw gateway restart

# 状态
openclaw gateway status

# 查看服务
systemctl --user status openclaw-gateway.service --no-pager
```

---

## 5) 回滚/关闭自动注入

```bash
bash scripts/disable_wsl_clash_proxy_service.sh
```

---

## 6) 常见问题

### Q1: 重启后看到 `RPC probe: failed 1006`
通常是 warm-up 窗口，等待 5~10 秒再执行一次：

```bash
openclaw gateway status
```

### Q2: 为什么我直接 `node ... gateway` 启动时没有代理？
因为自动代理依赖 systemd 的 `ExecStartPre + EnvironmentFile`。  
请用：

```bash
openclaw gateway restart
# 或
systemctl --user restart openclaw-gateway.service
```

### Q3: `oc` 命令不可用
`oc` 不是通用官方命令。请统一使用 `openclaw` 和本仓库脚本。

---

## 7) 快速自检命令（手动版）

```bash
openclaw gateway status
pid=$(systemctl --user show -p MainPID --value openclaw-gateway.service)
tr '\0' '\n' < /proc/$pid/environ | grep -Ei '^(http|https|no)_proxy='
```
