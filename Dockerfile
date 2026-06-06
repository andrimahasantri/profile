# syntax=docker/dockerfile:1

# ---- build ----
# node:22-slim (Debian/glibc) cocok dengan optional deps native yang di-declare
# project: @rollup/rollup-linux-x64-gnu & @img/sharp-linux-x64 (varian glibc,
# bukan musl/Alpine).
FROM node:22-slim AS build
WORKDIR /app
# SELFHOST memilih adapter Node standalone di astro.config.mjs
ENV SELFHOST=true
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# ---- runtime ----
FROM node:22-slim AS runtime
WORKDIR /app
ENV NODE_ENV=production \
    HOST=0.0.0.0 \
    PORT=4321
# Hanya yang dibutuhkan untuk menjalankan server SSR
COPY --from=build /app/dist ./dist
COPY --from=build /app/node_modules ./node_modules
COPY --from=build /app/package.json ./package.json
EXPOSE 4321
CMD ["node", "./dist/server/entry.mjs"]
