#!/usr/bin/env bash
# 构建并部署到 root@miao.vesein.dev(Caddy 静态站点,/var/www/miao)
set -euo pipefail

cd "$(dirname "$0")"

bun run build
# dl/ 是镜像目录(二进制/安装脚本),由 VPS 侧 cron 同步,不属于 Astro 产物,不能删
rsync -avz --delete --exclude='/dl/' dist/ root@miao.vesein.dev:/var/www/miao/

echo "Deployed: https://miao.vesein.dev"
