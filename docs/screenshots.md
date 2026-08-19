# 面板截图获取方式

官网用到的面板截图（`public/assets/panel.webp`）不是手摆的，是从真实运行的面板截取的。本文档记录完整流程，更新截图时照做即可。

## 前置条件

- miao 后端在跑（systemd 服务或 dev 二进制均可），面板地址 `http://localhost:6161`
- 安装 agent-browser（本机已有）
- 面板里有足够的数据让页面"满"：若干节点（订阅/手动）、几条自定义规则、最好有一点活跃连接

## 流程

### 1. 设定视口

```bash
agent-browser set viewport 1440 1400
```

高度 1400 是量出来的，不是拍的：先打开页面量右列内容高度，保证「自定义规则」卡完整入镜：

```js
// agent-browser eval,返回右列内容高度,按需调整视口
// 所需视口高度 ≈ 96(页面上下留白) + 76(融合顶栏) + 16 + 右列内容高度 + 16 + 184(活跃链接条带)
document.querySelector('.right-column').scrollHeight
```

### 2. 打开页面并等待数据加载

```bash
agent-browser open "http://localhost:6161/?v=$(date +%s)"   # 带 query 绕过 HTML 缓存
sleep 5                                                     # 等节点/规则/连接数据渲染
```

### 3. 打码（关键步骤)

截图前对敏感信息做 DOM 级模糊（纯客户端样式，不影响后端数据）。直接粘贴这段到 `agent-browser eval`:

```js
(() => {
  const blur = (el) => { el.style.filter = 'blur(6px)'; el.style.userSelect = 'none' }
  // 注意:节点名里的 IP 是横杠编码(vps-5-78-217-242),正则要同时吃横杠和点
  const ipish = (t) => /\d{1,3}[-.]\d{1,3}[-.]\d{1,3}[-.]\d{1,3}/.test(t)

  // 当前节点横幅/顶栏 chip 的 server:port（横幅已迁移为顶栏 chip，旧选择器保留兜底）
  document.querySelectorAll('.current-node-banner .banner-meta, .topbar .chip .chip-meta, [class*="current-node"] .banner-meta').forEach(blur)

  const cards = [...document.querySelectorAll('.panel-card')]
  const byTitle = (t) => cards.find(c => c.querySelector('.section-title-wrap')?.textContent.includes(t))

  // 手动节点卡:行为「名称 .rule-value + 协议 .badge」,名字含 IP 的码名称
  // (v0.39 起不再有 server:port 的 meta 行;.list-row-meta 分支保留兑底)
  byTitle('手动节点')?.querySelectorAll('.list-row').forEach(row => {
    row.querySelectorAll('.list-row-meta').forEach(blur)
    const name = row.querySelector('.rule-value') || row.querySelector('.list-row-title')
    if (name && ipish(name.textContent)) blur(name)
  })

  // 订阅管理卡:链接(即使 UI 截断显示,域名和 token 后缀仍可见)
  byTitle('订阅管理')?.querySelectorAll('.list-row .list-row-title').forEach(blur)

  // 左侧节点网格:名字含 IP 的 tile
  document.querySelectorAll('.proxy-tile').forEach(tile => {
    if (ipish(tile.textContent)) tile.querySelectorAll('.proxy-node-name, .proxy-tag').forEach(blur)
  })

  return 'masked'
})()
```

**规则卡的规则值不打全码**(打了卡片就没法看了)，但要人工过一眼：域名关键词/进程名等是否适合公开。不适合的值按同样方式单独模糊。

### 4. 截图

```bash
agent-browser screenshot /tmp/miao-panel.png
# 官网使用 WebP(体积约为 PNG 的 1/3):
magick /tmp/miao-panel.png -quality 85 public/assets/panel.webp
# 主仓库 README 直接引用官网 URL(https://miao.vesein.dev/assets/panel.webp),不再单独存档
```

## 注意事项（都踩过）

- **打码是一次性的**：页面刷新/重新打开后样式丢失，每次截图前都要重跑打码脚本。数据轮询重渲染一般不影响已设置的 inline style，但若发现模糊失效，重跑即可
- **`eval` 的 JS 上下文跨调用保留**：同名 `const` 再声明会报错，脚本必须用 IIFE 包裹（上面给的就是）
- **截图前先睡几秒**：节点延迟、连接统计都是异步加载，立刻截会得到半成品
- **活跃链接条可遇不可求**：没有活跃连接时该区域显示占位文案"暂无活跃链接"。想要卡片效果，截图前制造点流量（刷几个网页）；域名会真实显示在卡片上，挑中性的刷
- 备选方案：DOM 打码搞不定的场景，先截图再用 ImageMagick 画黑框（`convert in.png -draw "rectangle x1,y1 x2,y2" -fill black out.png`)，坐标用 `getBoundingClientRect()` 量

## 当前官网截图的存档

- 官网使用：`public/assets/panel.webp`（1440×1400，已打码，WebP 85）
- 官网 OG 卡片：`public/assets/og.png`（1200×630，PNG——部分抓取器不认 WebP，OG 图保持 PNG；由首页 hero 截图裁切生成）
- 主仓库使用：README 直接引用 `https://miao.vesein.dev/assets/panel.webp`，仓库内不再存档截图
