# syntax=docker/dockerfile:1
ARG UV_VERSION=0.11.7
FROM ghcr.io/astral-sh/uv:${UV_VERSION} AS uv

FROM python:3.11-slim-bookworm AS base
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    UV_PROJECT_ENVIRONMENT=/opt/venv \
    UV_PYTHON_DOWNLOADS=never \
    UV_LINK_MODE=copy \
    PATH="/opt/venv/bin:$PATH"
WORKDIR /workspace/GPT-SoVITS
RUN apt update && apt install -y --no-install-recommends bash ca-certificates curl ffmpeg libgomp1 libsndfile1 && rm -rf /var/lib/apt/lists/*
COPY --from=uv /uv /uvx /usr/local/bin/

FROM base AS dependencies
ARG TARGETARCH
ARG DEVICE=cu128
RUN test "$TARGETARCH" = amd64 || (echo 'uv.lock supports only linux/amd64 containers.' >&2; exit 1)
RUN apt-get update && apt-get install -y --no-install-recommends build-essential cmake pkg-config && rm -rf /var/lib/apt/lists/*
COPY pyproject.toml uv.lock .python-version ./
COPY Docker/install_wrapper.sh /usr/local/bin/install-dependencies
RUN --mount=type=cache,target=/root/.cache/uv bash /usr/local/bin/install-dependencies "$DEVICE"

FROM base AS runtime
ARG DEVICE=cu128
ENV GPT_SOVITS_DEVICE=${DEVICE} \
    WEBUI_LANGUAGE=zh_CN \
    MODEL_SOURCE=ModelScope \
    DOWNLOAD_MODELS=true \
    DOWNLOAD_UVR5=false \
    NVIDIA_DRIVER_CAPABILITIES=compute,utility \
    PYTHONPATH="/workspace/GPT-SoVITS:/workspace/GPT-SoVITS/GPT_SoVITS/BigVGAN:/workspace/GPT-SoVITS/tools:/workspace/GPT-SoVITS/tools/asr:/workspace/GPT-SoVITS/GPT_SoVITS:/workspace/GPT-SoVITS/tools/uvr5" \
    LD_LIBRARY_PATH="/opt/venv/lib/python3.11/site-packages/nvidia/cublas/lib:/opt/venv/lib/python3.11/site-packages/nvidia/cudnn/lib:/opt/venv/lib/python3.11/site-packages/torch/lib"
LABEL org.opencontainers.image.title="GPT-SoVITS-Reforged" \
      org.opencontainers.image.description="A modern, reproducible, and developer-friendly distribution of GPT-SoVITS"
COPY --from=dependencies /opt/venv /opt/venv
COPY . .
COPY --chmod=755 Docker/entrypoint.sh /usr/local/bin/gpt-sovits-entrypoint
EXPOSE 9871 9872 9873 9874 9880
ENTRYPOINT ["bash", "/usr/local/bin/gpt-sovits-entrypoint"]
CMD ["webui"]
