//
//  server.js
//  Sinian Signaling Server
//

const http = require('http');
const url = require('url');

let WebSocket;
try {
  WebSocket = require('ws');
} catch (e) {
  console.log('Notice: ws module not installed yet. Run "npm install" in server directory.');
}

const PORT = process.env.PORT || 8080;

// 情侣房间会话管理: Map<pairCode, Set<WebSocket>>
const rooms = new Map();
// 设备 Token 缓存: Map<pairCode, Set<pushToken>>
const pushTokens = new Map();

const server = http.createServer((req, res) => {
  const parsedUrl = url.parse(req.url, true);

  // 基础跨域头
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    res.writeHead(204);
    res.end();
    return;
  }

  // 健康检查与状态
  if (parsedUrl.pathname === '/health' || parsedUrl.pathname === '/') {
    const roomDetails = {};
    for (const [code, clients] of rooms.entries()) {
      roomDetails[code] = clients.size;
    }
    res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8' });
    res.end(JSON.stringify({
      status: 'ok',
      service: 'Sinian 情侣信令服务',
      time: new Date().toISOString(),
      activeRooms: rooms.size,
      roomDetails
    }));
    return;
  }

  // 生成随机配对码
  if (parsedUrl.pathname === '/api/pair/generate' && req.method === 'POST') {
    const letters = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    let code = 'LOVE-';
    for (let i = 0; i < 4; i++) {
      code += letters.charAt(Math.floor(Math.random() * letters.length));
    }
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ pairCode: code }));
    return;
  }

  // HTTP 测试触发想念事件
  if (parsedUrl.pathname === '/api/test/miss' && req.method === 'POST') {
    let body = '';
    req.on('data', chunk => { body += chunk; });
    req.on('end', () => {
      try {
        const data = JSON.parse(body || '{}');
        const pairCode = data.pairCode || 'LOVE-520';
        broadcastToRoom(pairCode, null, {
          type: 'miss_you',
          senderName: data.senderName || '测试伴侣',
          message: data.message || '从云端发来的测试想念 ❤️',
          emoji: data.emoji || '🥰',
          actionType: data.actionType || 'tap',
          timestamp: Date.now() / 1000
        });
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ success: true, broadcasted: true }));
      } catch (err) {
        res.writeHead(400, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ error: err.message }));
      }
    });
    return;
  }

  res.writeHead(404);
  res.end('Not Found');
});

function broadcastToRoom(pairCode, senderWs, payload) {
  const clients = rooms.get(pairCode);
  if (!clients) return 0;

  const messageStr = JSON.stringify(payload);
  let count = 0;
  for (const client of clients) {
    if (client !== senderWs && client.readyState === 1 /* OPEN */) {
      client.send(messageStr);
      count++;
    }
  }
  return count;
}

if (WebSocket) {
  const wss = new WebSocket.Server({ server });

  wss.on('connection', (ws, req) => {
    const parsedUrl = url.parse(req.url, true);
    const pairCode = parsedUrl.query.pairCode || 'LOVE-520';

    if (!rooms.has(pairCode)) {
      rooms.set(pairCode, new Set());
    }
    const room = rooms.get(pairCode);
    room.add(ws);

    console.log(`[+] 客户端加入房间 [${pairCode}], 当前在线人数: ${room.size}`);

    // 向刚连接的客户端发送房间当前状态
    ws.send(JSON.stringify({
      type: 'room_status',
      pairCode,
      roomSize: room.size,
      partnerOnline: room.size >= 2
    }));

    // 如果房间内有 2 个人及以上，通知房间内所有人伴侣已连接
    if (room.size >= 2) {
      for (const client of room) {
        if (client.readyState === 1 /* OPEN */) {
          client.send(JSON.stringify({ type: 'partner_connected', pairCode, roomSize: room.size }));
        }
      }
    }

    ws.on('message', (message) => {
      try {
        const data = JSON.parse(message.toString());
        console.log(`[Msg] 来自 [${pairCode}] 的事件:`, data.type);

        if (data.type === 'miss_you') {
          // 转发想念给另一半
          const sentCount = broadcastToRoom(pairCode, ws, data);
          console.log(`    已向伴侣转发 (在线目标数: ${sentCount})`);
        } else if (data.type === 'register_push_token') {
          if (!pushTokens.has(pairCode)) {
            pushTokens.set(pairCode, new Set());
          }
          pushTokens.get(pairCode).add(data.pushToken);
          console.log(`    已登记灵动岛 Push Token: ${data.pushToken.slice(0, 12)}...`);
        }
      } catch (e) {
        console.error('解析消息失败:', e);
      }
    });

    ws.on('close', () => {
      room.delete(ws);
      if (room.size === 0) {
        rooms.delete(pairCode);
      } else {
        // 通知另一半伴侣离线
        broadcastToRoom(pairCode, ws, { type: 'partner_disconnected', pairCode });
      }
      console.log(`[-] 客户端退出房间 [${pairCode}], 剩余在线人数: ${room.size}`);
    });
  });
}

server.listen(PORT, () => {
  console.log(`==========================================`);
  console.log(`❤️  Sinian 信令服务器已就绪!`);
  console.log(`   HTTP/WS 监听端口: ${PORT}`);
  console.log(`   健康检查接口: http://localhost:${PORT}/health`);
  console.log(`==========================================`);
});
