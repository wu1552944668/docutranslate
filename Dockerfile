FROM python:3.11-slim
LABEL authors="xunbu"

# 设置环境变量
ENV UV_INDEX_URL=https://pypi.tuna.tsinghua.edu.cn/simple
ENV UV_HTTP_TIMEOUT=300
ENV UV_COMPILE_BYTECODE=1
ENV PATH="/app/.venv/bin:$PATH"
# 定义输出目录环境变量
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

# 4. 精准安装
ARG DOC_VERSION=latest
RUN if [ "$DOC_VERSION" = "latest" ]; then \
        uv pip install "docutranslate[mcp]"; \
    else \
        uv pip install "docutranslate[mcp]==${DOC_VERSION}"; \
    fi

# 5. 创建挂载点并赋予权限，防止映射后无写入权限
RUN mkdir -p ${DOCUTRANSLATE_OUTPUT_DIR} && chmod 777 ${DOCUTRANSLATE_OUTPUT_DIR}
VOLUME ${DOCUTRANSLATE_OUTPUT_DIR}

ENV DOCUTRANSLATE_PORT=8010
EXPOSE 8010

# 6. 启动命令（附带轻量级后台清理进程：每小时检查一次，若目录总大小超1024MB，则删除7天前的jsonl文件）
ENTRYPOINT ["sh", "-c", "while true; do if [ \"$(du -sm $DOCUTRANSLATE_OUTPUT_DIR | awk '{print $1}')\" -gt 1024 ]; then find $DOCUTRANSLATE_OUTPUT_DIR -name '*.jsonl' -type f -mtime +7 -delete; fi; sleep 3600; done & docutranslate -i --with-mcp"]

# ================= 部署及开机自启说明 =================
# 构建镜像:
# docker build -t xunbu/docutranslate:latest .
#
# 运行并设置开机自启 (--restart=always) 及 目录挂载:
# docker run -d \
#   --name docutranslate \
#   --restart=always \
#   -p 8010:8010 \
#   -v $(pwd)/output:/app/output \
#   xunbu/docutranslate:latest