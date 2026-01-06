# syntax=docker/dockerfile:1.6

########################
# 1) FRONTEND BUILDER
########################
FROM --platform=$BUILDPLATFORM node:20-bookworm AS frontend
WORKDIR /src/frontend

ENV NODE_OPTIONS=--dns-result-order=ipv4first

COPY frontend/package.json frontend/yarn.lock ./

RUN --mount=type=cache,target=/root/.cache/yarn \
    corepack enable \
 && yarn config set network-timeout 600000 -g \
 && yarn config set registry https://registry.npmjs.org/ -g \
 && yarn install --frozen-lockfile --non-interactive

COPY frontend/ ./
RUN NODE_OPTIONS=--openssl-legacy-provider yarn build


########################
# 2) BACKEND BUILDER
########################
FROM --platform=$BUILDPLATFORM python:3.12-slim-bookworm AS backend
ENV PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PIP_NO_CACHE_DIR=1 \
    POETRY_NO_INTERACTION=1 \
    POETRY_VIRTUALENVS_IN_PROJECT=true

WORKDIR /app

# Build-Tools nur für Build-Stage (wenn Wheels kompiliert werden müssen)
RUN apt-get update && apt-get install -y --no-install-recommends \
      build-essential gcc \
    && rm -rf /var/lib/apt/lists/*

RUN pip install --no-cache-dir "poetry>=1.8"
# 1) nur lock + deps (cachebar)
COPY pyproject.toml poetry.lock ./
RUN poetry install --only main --no-root
# Nur Dependencies (Cache Layer)
COPY . .
RUN poetry install --only main


########################
# 3) RUNTIME
########################
FROM --platform=$TARGETPLATFORM python:3.12-slim-bookworm AS runtime
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

# Runtime libs: minimal halten; bei ImportError ergänzen
RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# venv + app übernehmen
COPY --from=backend /app/.venv /app/.venv
COPY --from=backend /app /app
ENV PATH="/app/.venv/bin:$PATH"

# Frontend-Assets übernehmen (Pfad/Output ggf. anpassen)
# CRA -> build, Vite -> dist
COPY --from=frontend /src/frontend/dist /app/frontend/dist

# Startkommando anpassen:
# Beispiele:
# CMD ["waitress-serve","--listen=0.0.0.0:8000","mariner.app:app"]
# oder:
EXPOSE 5000
CMD ["waitress-serve", "--listen=0.0.0.0:5000", "mariner.server.app:app"]
