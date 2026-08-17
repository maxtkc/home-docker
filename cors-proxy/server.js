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

const server = corsAnywhere.createServer({
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
});

// Browsers and Traefik collapse // in URL paths, turning /https://host into /https:/host.
// Restore the double-slash before cors-anywhere parses the target.
server.prependListener('request', (req) => {
  req.url = req.url.replace(/^\/(https?:)\/(?!\/)/, '/$1//');

  // Some real browser requests (direct downloads, certain extensions) omit
  // Origin even though the page making the request is one we trust. Fall
  // back to Referer's origin so those aren't rejected by requireHeader.
  if (!req.headers.origin && req.headers.referer) {
    try {
      const refererOrigin = new URL(req.headers.referer).origin;
      if (allowedOrigins.includes(refererOrigin)) {
        req.headers.origin = refererOrigin;
      }
    } catch (_) {
      // ignore malformed referer
    }
  }

  // Log enough context to diagnose the next missing-header rejection
  // without needing to reproduce it live.
  if (!req.headers.origin && !req.headers['x-requested-with']) {
    console.log(
      `[missing-origin] url=${req.url} referer=${req.headers.referer || '-'} ua=${req.headers['user-agent'] || '-'}`,
    );
  }
});

server.listen(PORT, '0.0.0.0', () => {
  console.log(`cors-anywhere listening on port ${PORT}`);
});
