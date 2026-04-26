'use strict';
const corsAnywhere = require('cors-anywhere');
const ipaddr = require('ipaddr.js');
const PORT = parseInt(process.env.PORT || '8080', 10);

const allowedOrigins = (process.env.CORS_ALLOWED_ORIGINS || '')
  .split(',').map(s => s.trim()).filter(Boolean);

const BLOCKED_RANGES = new Set(['loopback', 'private', 'linkLocal', 'uniqueLocal', 'multicast', 'broadcast']);

function isPrivateHost(host) {
  const hostname = host.replace(/:\d+$/, '');
  if (hostname === 'localhost' || hostname.endsWith('.local') || hostname.endsWith('.internal')) {
    return true;
  }
  try {
    return BLOCKED_RANGES.has(ipaddr.parse(hostname).range());
  } catch (_) {
    return false; // not an IP literal — allow through
  }
}

corsAnywhere.createServer({
  originWhitelist: allowedOrigins,
  removeHeaders: ['cookie', 'authorization'],
  requireHeader: ['origin'],
  handleInitialRequest: (req, res, location) => {
    if (!location) {
      res.writeHead(400, { 'Content-Type': 'text/plain' });
      res.end('Bad Request: invalid or missing target URL');
      return true;
    }
    if (isPrivateHost(location.host)) {
      res.writeHead(403, { 'Content-Type': 'text/plain' });
      res.end('Forbidden: private network targets not allowed');
      return true;
    }
    return false;
  },
}).listen(PORT, '0.0.0.0', () => {
  console.log(`cors-anywhere listening on port ${PORT}`);
});
