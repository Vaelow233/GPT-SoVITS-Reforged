# Docker Configuration Guide

Images use Python 3.11 and `uv sync --locked --no-dev --extra <device>`. Supported backends are `cpu`, `cu126` and `cu128`, on **Linux amd64 only**. Models are downloaded at runtime and are not included in the image.

`--locked` verifies that the lockfile matches the project metadata and fails if it needs updating. Image builds do not modify the lockfile. After changing dependencies, run `uv lock`, review the diff and verify it with `uv lock --check` before rebuilding.

## Start with Compose

Run from the repository root with Docker Engine / Docker Desktop (Linux containers), BuildKit and Docker Compose v2. NVIDIA services additionally need a compatible host NVIDIA driver and NVIDIA Container Toolkit configured for Docker, see [Docker GPU setup](https://docs.docker.com/engine/containers/gpu/).

```bash
docker compose up --build -d cu128
docker compose logs -f cu128
```

Replace `cu128` with `cu126` or `cpu` in all commands to select another backend.
Run only one backend at a time because they share host ports. Before switching, stop the current service, e.g. `docker compose stop cu128`.

The first startup downloads pretrained models, G2PW and language resources, this can take a while. Follow the logs until the Web UI is ready, then open http://localhost:9874. 

Ports 9871–9873 are for optional tools started from the WebUI. Port 9880 is reserved for a separately launched API. The default command does not start the API.

## Configuration

Set these variables in a root `.env` file or your shell before running Compose:

| Variable          | Default      | Description                                                          |
|-------------------|--------------|----------------------------------------------------------------------|
| `MODEL_SOURCE`    | `ModelScope` | `HF`, `HF-Mirror` or `ModelScope`                                    |
| `DOWNLOAD_MODELS` | `true`       | Check and install models and language resources before WebUI startup |
| `DOWNLOAD_UVR5`   | `false`      | Install optional UVR5 weights; use `true` to enable                  |
| `WEBUI_LANGUAGE`  | `zh_CN`      | WebUI language, e.g. `zh_CN`                                         |
| `IS_HALF`         | `true`       | GPU half precision; CPU forces it off                                |
| `SHM_SIZE`        | `16g`        | Container shared-memory limit                                        |

Keep `DOWNLOAD_MODELS=true` to reuse existing resources and restore NLTK/OpenJTalk data in `/opt/venv` after recreating a container. Set it to `false` only when the current container already has all required models and language resources.

Compose publishes ports 9871–9874 and 9880 on all host interfaces using the `ports` entries in `docker-compose.yaml`.

For example, this `.env` selects Hugging Face and UVR5:

```dotenv
MODEL_SOURCE=HF
DOWNLOAD_UVR5=true
```

To explicitly download or repair resources:

```bash
docker compose run --rm --no-deps cu128 download-models --download-uvr5
docker compose run --rm --no-deps cu128 download-models --source HF --force
```

These commands reuse model files and archives in the checkout. Language resources installed in the one-off container are restored again at normal WebUI startup.

## Build without Compose

```bash
bash docker_build.sh --device cu128
bash docker_build.sh --device cpu
# Equivalent, also usable from PowerShell:
docker build --platform linux/amd64 --build-arg DEVICE=cu128 -t gpt-sovits-reforged:local-cu128 .
```

The build script defaults to `cu128` and `gpt-sovits-reforged:local-cu128`.
The uv version is pinned in the Dockerfile and can be overridden using the `UV_VERSION` build argument. 
BuildKit caches dependency downloads; model downloads are independent of image builds. 
The final image contains FFmpeg shared libraries and the locked Python dependencies, without the C++ build toolchain. 
Optional custom CUDA kernels requiring `nvcc` are not included.

For example, with Bash on Linux:

```bash
docker run --rm -it --init --gpus all --shm-size 16g \
  -p 9874:9874 \
  -v "$PWD:/workspace/GPT-SoVITS" \
  -v gpt-sovits-model-cache:/root/.cache \
  gpt-sovits-reforged:local-cu128
```

For CPU, build/select `local-cpu` and omit `--gpus all`. Publish additional ports as needed for tools.
