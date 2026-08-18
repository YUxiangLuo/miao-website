# mirror/ — 镜像站服务端文件存档

镜像站（`https://miao.vesein.dev/dl/`）的服务端组件只存在于 VPS 上，本目录是其版本化存档。
**服务器上的文件是 live 副本，本目录不自动部署**；改动后手动 scp 同步。

| 本目录 | 服务器位置 | 作用 |
| --- | --- | --- |
| `miao-mirror-sync.sh` | `/usr/local/sbin/miao-mirror-sync.sh` | 从 GitHub 拉最新 release 两个 Linux 二进制（ELF 校验 + 原子替换），重生成 `sha256sums.txt` 与 `VERSION`；`install.sh`/`remove.sh` 每次跟随 master 刷新 |
| `miao-mirror` | `/etc/cron.d/miao-mirror` | 每 6 小时调用同步脚本，日志 `/var/log/miao-mirror.log` |
| `dl-index.html` | `/var/www/miao/dl/index.html` | `/dl/` 目录索引页（Caddy `file_server` 无目录浏览，无此文件则 `/dl/` 404） |

## 部署边界

- `dl/` 目录归 cron 同步脚本管；`deploy.sh` 的 `rsync --delete --exclude='/dl/'` 不会触碰它
- Caddy（`/etc/caddy/Caddyfile`）把 `/install.sh`、`/remove.sh` rewrite 到 `dl/` 下同名文件——脚本跟随主仓库 master，与 release 解耦
- 同步脚本只写自己那六个文件，`dl/index.html` 不会被同步冲掉
