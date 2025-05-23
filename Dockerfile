# 前端构建
FROM node:20 AS frontend
WORKDIR /app
COPY frontend/ .
RUN npm install -g pnpm
RUN pnpm i --force && pnpm run build

# 后端
FROM python:3.9-slim
WORKDIR /app

# 安装依赖
RUN apt-get update && apt-get install -y jq curl openssl wget
COPY backend/ .
RUN pip install -r requirements.txt
# 拷贝前端静态文件到后端
COPY --from=frontend /app/dist ./static

ENV FLASK_RUN_PORT=9731
EXPOSE 9731

# 启动命令
CMD ["python", "main.py"]