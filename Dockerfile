# =========================
# 1) BUILDER: build + .deb
# =========================
FROM debian:bullseye-slim AS builder

ENV NODE_OPTIONS=--dns-result-order=ipv4first \
    PATH=$PATH:/root/.local/bin \
    PIP_DEFAULT_TIMEOUT=600 \
    PIP_TIMEOUT=600 \
    PIP_RETRIES=100

RUN apt-get update && apt-get install -y --no-install-recommends \
    sudo dpkg-dev debhelper dh-virtualenv \
    python3 python3-venv python3-dev \
    build-essential libffi-dev zlib1g-dev \
    libssl-dev libpcap-dev libcap-dev libxslt-dev libxml2-dev \
    libavcodec-dev libavformat-dev libswscale-dev libdrm-dev libasound2-dev \
    libwebp-dev libjpeg62-turbo-dev \
    liblcms2-2 libopenjp2-7-dev libtiff5-dev libxcb1-dev libfreetype6-dev \
    liblapack3 libatlas-base-dev liblapack-dev \
    curl ca-certificates git \
 && rm -rf /var/lib/apt/lists/*

# Poetry
RUN curl -sSL https://install.python-poetry.org | python3 -

# Node 18 + Yarn classic
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - \
 && apt-get update && apt-get install -y --no-install-recommends nodejs \
 && rm -rf /var/lib/apt/lists/* \
 && corepack disable || true \
 && npm i -g yarn@1.22.22

WORKDIR /build
COPY . /build/

# Frontend build
WORKDIR /build/frontend
RUN yarn config set network-timeout 600000 \
 && yarn config set registry https://registry.npmjs.org \
 && yarn install --frozen-lockfile \
 && yarn build

# Python + deb build
WORKDIR /build
RUN test -f poetry.lock
RUN poetry config virtualenvs.create false
RUN poetry install --only main --no-interaction --no-ansi
RUN poetry build
RUN poetry self add poetry-plugin-export
RUN poetry export -f requirements.txt --without-hashes -o /tmp/requirements.txt

WORKDIR /build/dist
RUN dpkg-buildpackage -us -uc

# Collect deb(s)
RUN mkdir -p /out \
 && find /build -maxdepth 3 -type f -name "*.deb" -print -exec cp -v {} /out/ \;


# =========================
# 2) RUNTIME: install .deb
# =========================
FROM debian:bullseye-slim AS runtime

ENV NODE_OPTIONS=--dns-result-order=ipv4first \
    PYTHONUNBUFFERED=1

# Minimal runtime deps (no -dev!)
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl \
    gcc libc6-dev libcap-dev python3-dev \
    python3 python3-venv python3-distutils \
    libpcap0.8 \
    libssl1.1 \
    libxml2 libxslt1.1 \
    libjpeg62-turbo libwebp6 libtiff5 libpng16-16 libfreetype6 zlib1g \
    libatlas3-base liblapack3 libgfortran5 \
    libavcodec58 libavformat58 libavutil56 libswscale5 libswresample3 \
    libdrm2 libxcb1 libxau6 libasound2 \
 && rm -rf /var/lib/apt/lists/*

COPY --from=builder /out/*.deb /tmp/
COPY --from=builder /tmp/requirements.txt /tmp/requirements.txt

RUN set -eux; \
    dpkg -i /tmp/mariner3d_*.deb || true; \
    dpkg -s mariner3d || true; \
    apt-get update; \
    apt-get -y -f install; \
    dpkg -s mariner3d; 

RUN /opt/venvs/mariner3d/bin/python -m pip install -r /tmp/requirements.txt

EXPOSE 5000

# Start mariner from /usr/bin/mariner
CMD ["mariner"]

# =========================
# 3) ARTIFACTS: export .deb
# =========================
FROM scratch AS artifacts
COPY --from=builder /out/ /out/







