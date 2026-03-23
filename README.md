# oc-wsl-clash-proxy

让 OpenClaw 在 WSL2 中自动使用 Windows 主机代理（Clash / Clash Verge / V2RayN / sing-box 等），并在 systemd 常驻模式下每次启动自动刷新代理配置，提升 API 连通性与稳定性。

## 适用场景

- OpenClaw 运行在 WSL2
- 代理软件运行在 Windows 主机
- 需要常驻服务（systemd）稳定可用
- 需要自动处理 Windows IP 与端口变化

## 功能特性

- 自动探测 Windows 主机 IP（/etc/resolv.conf + route fallback）
- 自动探测常见代理端口（可自定义）
- 支持固定代理地址覆盖（PROXY_URL）
- 自动写入并刷新 ~/.openclaw/openclaw-proxy.env
- 注入 openclaw-gateway.service 的 ExecStartPre 启动前刷新逻辑
- 一键 daemon-reload + enable + restart（systemd user）

## 快速开始

bash skills/oc-wsl-clash-proxy/scripts/enable_wsl_clash_proxy_service.sh

## 可选参数

- PROXY_URL：固定代理 URL（最高优先级），例如 http://172.21.208.1:7890
- CLASH_PORT：单一优先端口（兼容旧参数）
- PROXY_PORTS：自动探测端口列表（逗号分隔）
- SERVICE_NAME：默认 openclaw-gateway.service

### 示例

# 1) 全自动（推荐）
bash skills/oc-wsl-clash-proxy/scripts/enable_wsl_clash_proxy_service.sh

# 2) 固定代理地址
PROXY_URL=http://172.21.208.1:7890 bash skills/oc-wsl-clash-proxy/scripts/enable_wsl_clash_proxy_service.sh

# 3) 自定义端口探测顺序
PROXY_PORTS=7897,7890,20171,9090 bash skills/oc-wsl-clash-proxy/scripts/enable_wsl_clash_proxy_service.sh

## 验证

openclaw gateway status
systemctl --user status openclaw-gateway.service --no-pager
journalctl --user -u openclaw-gateway.service -n 120 --no-pager

## 常见问题

### 代理不可达 / 启动失败

- 确认 Windows 代理软件已运行
- 确认已开启 Allow LAN / 局域网连接
- 检查防火墙是否拦截对应端口

### 偶发短时断线

- 多为服务重启预热窗口或上游 API 瞬时波动
- 可用诊断脚本快速定位：

bash scripts/oc-quick-diagnose.sh

## 兼容说明

- 本项目是 WSL 原生部署方案
- Docker / OnePanel 场景建议使用独立适配方案（避免配置冲突）

## 合规声明

本项目仅用于合法合规的网络连通性与稳定性优化。
不提供代理节点、订阅链接或绕过策略。
请遵守所在地法律法规及第三方服务条款（ToS/AUP）。

## License

See LICENSE in repository.
