# syntax=docker/dockerfile:1.4

FROM node:20.18-alpine AS base

ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"

RUN apk add --no-cache \
    python3 \
    make \
    g++ && \
    corepack enable && \
    ln -sf /usr/bin/python3 /usr/bin/python

WORKDIR /app

FROM base AS prod-deps

COPY package.json pnpm-lock.yaml ./
RUN --mount=type=cache,id=pnpm,target=/pnpm/store pnpm install --prod --frozen-lockfile

FROM base AS builder

COPY package.json pnpm-lock.yaml ./
RUN --mount=type=cache,id=pnpm,target=/pnpm/store pnpm install --frozen-lockfile
COPY . .
RUN pnpm build

FROM base

COPY --from=prod-deps /app/node_modules /app/node_modules
COPY --from=builder /app/.medusa ./
COPY --from=builder /app/tsconfig.json ./
COPY --from=builder /app/medusa-config.ts ./

WORKDIR /app/server

VOLUME ["/app/uploads", "/app/static"]

EXPOSE 9000

CMD ["pnpm", "start:prod"]