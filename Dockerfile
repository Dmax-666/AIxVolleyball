FROM python:3.9-slim-bookworm

# 基础环境
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PIP_DEFAULT_TIMEOUT=120 \
    PIP_INDEX_URL=https://pypi.tuna.tsinghua.edu.cn/simple \
    # 限制多线程库避免小机器内存暴涨
    OMP_NUM_THREADS=1 \
    MKL_NUM_THREADS=1 \
    NUMEXPR_NUM_THREADS=1 \
    MALLOC_ARENA_MAX=2 \
    LANG=C.UTF-8

WORKDIR /app

# ---- 系统依赖：包含运行时 + 临时构建依赖（构建后会清理）----
# 说明：
# - build-essential / python3-dev / pkg-config 仅为少数无轮子的包兜底，装完后会卸载
# - libxrender1 为运行库，避免 dev 体积
RUN apt-get update && apt-get install -y --no-install-recommends \
    ffmpeg \
    curl \
    ca-certificates \
    libgl1-mesa-glx \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender1 \
    libgomp1 \
    # 临时构建依赖（稍后卸载）
    build-essential \
    python3-dev \
    pkg-config \
 && rm -rf /var/lib/apt/lists/*

# 先拷 requirements 以最大化缓存命中
COPY requirements.txt .

# Python 依赖：优先二进制轮子，缺轮子则自动编译（因已装好构建工具）
RUN pip install --no-cache-dir --prefer-binary -r requirements.txt \
 && pip install --no-cache-dir gunicorn

# 拷贝项目
COPY . .

# 生成目录
RUN mkdir -p /app/output

# 运行期健康检查（即便不使用 compose 也能自检）
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
  CMD curl -fsS http://localhost:5000/api/health || exit 1

EXPOSE 5000

# 构建后清理临时构建依赖，降低镜像体积与攻击面
RUN apt-get purge -y --auto-remove build-essential python3-dev pkg-config || true \
 && rm -rf /var/lib/apt/lists/*

# 默认保守并可用环境变量覆盖：1 worker + 2 线程，更适合 2C2G
# 说明：Flask 在 gthread 下是线程安全的；如果你确实需要多进程，可把 WEB_CONCURRENCY 调到 2。
ENV WEB_CONCURRENCY=1 WEB_THREADS=2 GUNICORN_TIMEOUT=120
CMD ["sh","-c","exec gunicorn \
    -w ${WEB_CONCURRENCY} \
    --threads ${WEB_THREADS} \
    -b 0.0.0.0:5000 \
    --timeout ${GUNICORN_TIMEOUT} \
    --access-logfile - \
    --error-logfile - \
    backend.api.flask_api:app"]
