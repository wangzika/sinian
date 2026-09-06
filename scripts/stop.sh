#!/usr/bin/env bash
# ==============================================================================
#  思念 (Sinian) - 一键停止与清理脚本
# ==============================================================================

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PID_FILE="${PROJECT_ROOT}/.server.pid"
PORT="${PORT:-8080}"

echo "=================================================="
echo "      🛑 思念 (Sinian) 服务与程序关闭           "
echo "=================================================="

STOPPED=0

# 1. 停止 Node 服务 (通过 PID 文件)
if [ -f "${PID_FILE}" ]; then
  PID=$(cat "${PID_FILE}")
  if [ -n "${PID}" ] && ps -p "${PID}" > /dev/null 2>&1; then
    echo "🛑 正在停止信令服务 (PID: ${PID})..."
    kill "${PID}" 2>/dev/null || true
    sleep 1
    if ps -p "${PID}" > /dev/null 2>&1; then
      kill -9 "${PID}" 2>/dev/null || true
    fi
    STOPPED=1
  fi
  rm -f "${PID_FILE}"
fi

# 2. 检查本地监听端口 8080 是否仍被占用 (仅匹配 LISTEN 状态，避免误杀外联程序)
PORT_PID=$(lsof -ti tcp:${PORT} -sTCP:LISTEN 2>/dev/null || true)
if [ -n "${PORT_PID}" ]; then
  echo "🧹 释放端口 ${PORT} 监听进程 (PID: ${PORT_PID})..."
  kill -9 ${PORT_PID} 2>/dev/null || true
  STOPPED=1
fi

# 3. 按进程名称兜底清理当前目录下的 node server.js
PIDS_BY_NAME=$(pgrep -f "node.*server/server\.js" 2>/dev/null || true)
if [ -n "${PIDS_BY_NAME}" ]; then
  echo "🧹 终止残留 server.js 进程 (PID: ${PIDS_BY_NAME})..."
  kill -9 ${PIDS_BY_NAME} 2>/dev/null || true
  STOPPED=1
fi

if [ ${STOPPED} -eq 1 ]; then
  echo "✅ 信令服务已完全关闭并释放端口 ${PORT}。"
else
  echo "ℹ️  未发现运行中的信令服务。"
fi

# 4. 可选关闭 iOS 模拟器 (交互式或带 --all 参数)
CLOSE_SIM="n"
if [[ "$*" == *"--all"* ]]; then
  CLOSE_SIM="y"
elif [ -t 0 ]; then
  read -t 10 -p "是否同时关闭 Mac 上的 iOS 模拟器？(y/N, 默认N): " CLOSE_SIM || true
fi

if [[ "${CLOSE_SIM}" =~ ^[Yy]$ ]]; then
  echo "📱 正在退出 iOS 模拟器并关闭所有虚拟机..."
  osascript -e 'tell application "Simulator" to quit' 2>/dev/null || true
  xcrun simctl shutdown all 2>/dev/null || true
  echo "✅ 模拟器已关闭。"
fi

echo ""
echo "✨ 所有指定后台服务与程序已全部关闭。"
echo "=================================================="
