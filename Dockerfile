FROM node:18-alpine AS client-builder
WORKDIR /app/client
COPY client/package*.json ./
RUN npm ci
COPY client/ ./
RUN npm run build

FROM node:18-alpine AS server-builder
WORKDIR /app/server
COPY server/package*.json ./
RUN npm ci --only=production
COPY server/ ./

FROM node:18-alpine
WORKDIR /app
RUN apk add --no-cache dumb-init
COPY --from=server-builder /app/server ./server
COPY --from=client-builder /app/client/dist ./server/public
ENV NODE_ENV=production
ENV PORT=4000
EXPOSE 4000
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:4000/api/health', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})"
WORKDIR /app/server
CMD ["dumb-init", "node", "src/server.js"]
