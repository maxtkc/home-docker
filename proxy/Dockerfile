FROM nginxproxy/nginx-proxy:alpine

COPY uploadsize.conf /etc/nginx/conf.d/uploadsize.conf
COPY security-headers.conf /etc/nginx/conf.d/security-headers.conf
COPY websocket.conf /etc/nginx/conf.d/websocket.conf
COPY snap.kcfam.us_location /etc/nginx/vhost.d/snap.kcfam.us_location
