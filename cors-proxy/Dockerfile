FROM node:22-alpine
WORKDIR /app
RUN npm install --omit=dev cors-anywhere ipaddr.js
COPY server.js .
USER node
EXPOSE 8080
CMD ["node", "server.js"]
