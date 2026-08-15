#!/usr/bin/env bash
# 构建并部署到 root@miao.vesein.dev(Caddy 静态站点,/var/www/miao)
set -euo pipefail

cd "$(dirname "$0")"

bun run build
rsync -avz --delete dist/ root@miao.vesein.dev:/var/www/miao/

echo "Deployed: https://miao.vesein.dev"
