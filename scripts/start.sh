#!/usr/bin/env bash
# ==============================================================================
#  思念 (Sinian) - 一键启动脚本
# ==============================================================================

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SERVER_DIR="${PROJECT_ROOT}/server"
LOG_DIR="${PROJECT_ROOT}/logs"
PID_FILE="${PROJECT_ROOT}/.server.pid"
PORT="${PORT:-8080}"

mkdir -p "${LOG_DIR}"

echo "=================================================="
echo "      🌸 思念 (Sinian) 服务启动程序 🌸           "
echo "=================================================="

# 1. 检查本地监听端口是否已被占用 (仅检查 LISTEN 状态)
EXISTING_PID=$(lsof -ti tcp:${PORT} -sTCP:LISTEN 2>/dev/null || true)
if [ -n "${EXISTING_PID}" ]; then
  echo "⚠️  端口 ${PORT} 已有服务在监听 (PID: ${EXISTING_PID})。"
  echo "👉 若要重启，请先运行: ./scripts/stop.sh"
  exit 1
fi

# 2. 检查 node 环境
if ! command -v node >/dev/null 2>&1; then
  echo "❌ 错误: 未检测到 Node.js 环境，请先安装 Node.js (https://nodejs.org/)"
  exit 1
fi

# 3. 检查依赖
if [ ! -d "${SERVER_DIR}/node_modules" ]; then
  echo "📦 正在安装信令服务端依赖 (npm install)..."
  (cd "${SERVER_DIR}" && npm install --silent)
fi

# 4. 后台启动信令服务
echo "🚀 正在启动信令服务 (端口: ${PORT})..."
nohup node "${SERVER_DIR}/server.js" > "${LOG_DIR}/server.log" 2>&1 &
SERVER_PID=$!
echo "${SERVER_PID}" > "${PID_FILE}"
sleep 1

# 验证服务是否成功启动
if ps -p "${SERVER_PID}" > /dev/null; then
  echo "✅ 信令服务启动成功！(PID: ${SERVER_PID})"
else
  echo "❌ 信令服务启动失败，查看日志: ${LOG_DIR}/server.log"
  exit 1
fi

# 5. 获取本机可用 IP 地址列表
echo ""
echo "📱 请在 iPhone「思念」App 设置中填入以下对应的服务器 IP："
echo "--------------------------------------------------"
# 优先查找热点 IP (172.20.10.x)
HOTSPOT_IP=$(ifconfig 2>/dev/null | grep "inet 172.20.10\." | awk '{print $2}' | head -n 1 || true)
if [ -n "${HOTSPOT_IP}" ]; then
  echo "  🌟 [个人热点连接推荐]  ws://${HOTSPOT_IP}:${PORT}"
fi

# 查找无线网卡 Wi-Fi IP (en0)
WIFI_IP=$(ipconfig getifaddr en0 2>/dev/null || true)
if [ -n "${WIFI_IP}" ]; then
  echo "  📶 [Wi-Fi 局域网推荐]   ws://${WIFI_IP}:${PORT}"
fi

# 本地环回
echo "  💻 [本机模拟器调试]     ws://127.0.0.1:${PORT}"
echo "--------------------------------------------------"
echo "房间配对码：默认与另一台设备保持一致（如 5201314）"
echo ""

# 6. 可选启动模拟器 (交互式或带 --sim 参数)
LAUNCH_SIM="n"
if [[ "$*" == *"--sim"* ]]; then
  LAUNCH_SIM="y"
elif [ -t 0 ]; then
  read -t 10 -p "是否顺便启动 Mac 上的 iOS 模拟器？(y/N, 默认N): " LAUNCH_SIM || true
fi

if [[ "${LAUNCH_SIM}" =~ ^[Yy]$ ]]; then
  echo "📱 正在唤起 iOS 模拟器..."
  open -a Simulator
fi

echo ""
echo "🎉 全部就绪！"
echo "👉 查看实时日志: tail -f \"${LOG_DIR}/server.log\""
echo "👉 一键停止程序: ./scripts/stop.sh"
echo "=================================================="
