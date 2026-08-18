#!/usr/bin/env bash
# Miao 镜像站同步:从 GitHub 拉取最新 release 二进制与安装/卸载脚本
# 部署于 root@miao.vesein.dev,由 /etc/cron.d/miao-mirror 每 6 小时调用
set -euo pipefail

DL=/var/www/miao/dl
REPO=YUxiangLuo/miao
WIN_EXE=miao-windows-amd64-setup.exe

mkdir -p "$DL"

latest=$(curl -fsSL "https://api.github.com/repos/$REPO/releases/latest" | grep -oP '"tag_name"\s*:\s*"\K[^"]+')
current=$(cat "$DL/VERSION" 2>/dev/null || echo none)

# exe 缺失时也全量同步(兼容脚本升级前的旧镜像)
if [[ "$latest" != "$current" || ! -f "$DL/$WIN_EXE" ]]; then
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
  # Windows 安装包:PE(MZ)魔数校验,逻辑同上
  curl -fsSL --retry 3 "https://github.com/$REPO/releases/latest/download/$WIN_EXE" -o "$DL/$WIN_EXE.tmp"
  if [[ "$(head -c 2 "$DL/$WIN_EXE.tmp")" != "MZ" ]]; then
    echo "$WIN_EXE 不是有效 PE,中止(保留旧版本)" >&2
    rm -f "$DL/$WIN_EXE.tmp"
    exit 1
  fi
  chmod 644 "$DL/$WIN_EXE.tmp"
  mv "$DL/$WIN_EXE.tmp" "$DL/$WIN_EXE"
  (cd "$DL" && sha256sum miao-rust-linux-* "$WIN_EXE" > sha256sums.txt)
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
