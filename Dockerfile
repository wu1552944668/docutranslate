FROM python:3.11-slim
LABEL authors="xunbu"

# 设置环境变量
ENV UV_INDEX_URL=https://pypi.tuna.tsinghua.edu.cn/simple
ENV UV_HTTP_TIMEOUT=300
ENV UV_COMPILE_BYTECODE=1
ENV PATH="/app/.venv/bin:$PATH"
ENV DOCUTRANSLATE_OUTPUT_DIR="/app/output"

WORKDIR /app

# 1. 安装系统依赖
RUN sed -i 's/deb.debian.org/mirrors.aliyun.com/g' /etc/apt/sources.list.d/debian.sources \
    && apt-get update && apt-get install -y --no-install-recommends \
    pandoc \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# 2. 安装 uv
RUN pip install --no-cache-dir uv -i https://pypi.tuna.tsinghua.edu.cn/simple

# 3. 创建虚拟环境
RUN uv venv /app/.venv

# 4. 【核心修复：将当前目录下所有你修改过的代码复制到容器的 /app 目录】
COPY . /app

# 5. 【核心修复：从刚才拷贝进来的本地代码进行安装，而不是去网上拉取】
RUN uv pip install ".[mcp]"

# 6. 创建挂载点
RUN mkdir -p ${DOCUTRANSLATE_OUTPUT_DIR} && chmod 777 ${DOCUTRANSLATE_OUTPUT_DIR}
VOLUME ${DOCUTRANSLATE_OUTPUT_DIR}

ENV DOCUTRANSLATE_PORT=8010
EXPOSE 8010

# 7. 启动命令
ENTRYPOINT ["sh", "-c", "while true; do if [ \"$(du -sm $DOCUTRANSLATE_OUTPUT_DIR | awk '{print $1}')\" -gt 1024 ]; then find $DOCUTRANSLATE_OUTPUT_DIR -name '*.jsonl' -type f -mtime +7 -delete; fi; sleep 3600; done & docutranslate -i --with-mcp"]