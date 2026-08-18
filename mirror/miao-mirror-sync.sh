#!/usr/bin/env bash
# Miao 镜像站同步:从 GitHub 拉取最新 release 二进制与安装/卸载脚本
# 部署于 root@miao.vesein.dev,由 /etc/cron.d/miao-mirror 每 6 小时调用
set -euo pipefail

DL=/var/www/miao/dl
REPO=YUxiangLuo/miao

mkdir -p "$DL"

latest=$(curl -fsSL "https://api.github.com/repos/$REPO/releases/latest" | grep -oP '"tag_name"\s*:\s*"\K[^"]+')
current=$(cat "$DL/VERSION" 2>/dev/null || echo none)

if [[ "$latest" != "$current" ]]; then
  echo "new release: $latest (current: $current)"
  for arch in amd64 arm64; do
    f="miao-rust-linux-$arch"
    curl -fsSL --retry 3 "https://github.com/$REPO/releases/latest/download/$f" -o "$DL/$f.tmp"
    # ELF 校验:挡下载损坏或错误页
    if [[ "$(head -c 4 "$DL/$f.tmp")" != $'\x7fELF' ]]; then
      echo "$f 不是有效 ELF,中止(保留旧版本)" >&2
      rm -f "$DL/$f.tmp"
      exit 1
    fi
    chmod 755 "$DL/$f.tmp"
    mv "$DL/$f.tmp" "$DL/$f"
  done
  (cd "$DL" && sha256sum miao-rust-linux-* > sha256sums.txt)
  echo "$latest" > "$DL/VERSION"
  echo "updated to $latest"
else
  echo "already latest: $current"
fi

# 安装/卸载脚本跟随 master,每次强制刷新(文本小)
for s in install.sh remove.sh; do
  curl -fsSL "https://raw.githubusercontent.com/$REPO/master/$s" -o "$DL/$s.tmp" && mv "$DL/$s.tmp" "$DL/$s"
done
chmod 644 "$DL"/*.sh
