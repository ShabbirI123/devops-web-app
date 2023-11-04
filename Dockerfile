# Verwenden Sie ein Base-Image, das auf der gewünschten Architektur basiert
FROM --platform=linux/amd64 node:18 AS builder
WORKDIR /app
COPY package.json ./
RUN npm install
COPY . .
RUN npm run build

FROM --platform=linux/amd64 node:18 AS runner
WORKDIR /app
COPY --from=builder /app/next.config.js ./next.config.js
COPY --from=builder /app/public ./public
COPY --from=builder /app/.next ./.next
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./
COPY --from=builder /app/pages ./pages

EXPOSE 3000

CMD ["npm", "start"]
