# syntax=docker/dockerfile:1.6

########################
# 1) FRONTEND BUILDER
########################
FROM --platform=$BUILDPLATFORM node:20-bookworm AS frontend
WORKDIR /src/frontend

# Falls du npm nutzt:
COPY frontend/package.json frontend/package-lock.json ./
RUN npm ci

COPY frontend/ ./
# Falls Webpack/OpenSSL3 noch knallt, TEMPORÄR aktivieren:
# ENV NODE_OPTIONS=--openssl-legacy-provider
RUN npm run build


########################
# 2) BACKEND BUILsDER
########################
FROM --platform=$BUILDPLATFORM python:3.12-slim-bookworm AS backend
ENV PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PIP_NO_CACHE_DIR=1 \
    POETRY_NO_INTERACTION=1 \
    POETRY_VIRTUALENVS_IN_PROJECT=true

WORKDIR /src

# Build-Tools nur für Build-Stage (wenn Wheels kompiliert werden müssen)
RUN apt-get update && apt-get install -y --no-install-recommends \
      build-essential gcc \
    && rm -rf /var/lib/apt/lists/*

RUN pip install --no-cache-dir "poetry>=1.8"

# Nur Dependencies (Cache Layer)
COPY pyproject.toml poetry.lock ./
RUN poetry install --only main --no-root

# Quellcode
COPY . .

# Wenn dein Projekt ein Poetry-Package ist (meistens ja)
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
COPY --from=backend /src/.venv /app/.venv
COPY --from=backend /src /app

# Frontend-Assets übernehmen (Pfad/Output ggf. anpassen)
# CRA -> build, Vite -> dist
COPY --from=frontend /src/frontend/build /app/frontend/build

ENV PATH="/app/.venv/bin:$PATH"

EXPOSE 8000

# Startkommando anpassen:
# Beispiele:
# CMD ["waitress-serve","--listen=0.0.0.0:8000","mariner.app:app"]
# oder:
CMD ["python", "-m", "mariner"]