# CHANGELOG

本文件只记录**社区维护分支**相对上游 `dsh-purge@1.1.82` 的改动。
上游历史见 `release-notes.md`（保留原样，未改动）。

---

## 1.1.83 — 2026-11-12

首个社区维护版本。目标：让插件在 **dsh 0.2.2-rc.2**（桌面版现役版本）上真正可用。

### 修复

- **版本适配**：新增 `lib/compat-dsh-0.2.2.mjs`，提供 9 条针对 0.2.2-rc.2 的兼容补丁
  （`#932` / `#933` 等，取代上游已失配的 `#32` / `#53`）。
- **补丁注册**：`lib/core.js` 注入兼容补丁数组，纳入统一补丁表。
  改动共 4 处，累计 +467 字节：
  1. `import { COMPAT_PATCHES_RC2 } from "./compat-dsh-0.2.2.mjs";`
  2. `ALL_PATCHES = [...PATCHES, ...CODE_PATCHES, ...ENGINE_PATCHES, ...NEW_TOOL_PATCHES, ...COMPAT_PATCHES_RC2]`
  3. `targetFiles()` 新增 `harness-dev-context` 键
  4. 补丁 `#17` 增加 `markersAny: true`（多候选标记，命中任一即可）
- **换包失败兜底**：上游把 `app.asar` 改名为 `app.asar.bak` 的脚本在
  Windows 上极易失败（文件被占用 / 安全软件拦截），导致「补丁树已写好但运行时
  仍加载原版 asar」。新增 `scripts/` 三件套解决这个问题。

### 新增

| 文件 | 说明 |
|---|---|
| `lib/compat-dsh-0.2.2.mjs` | 0.2.2-rc.2 兼容补丁集 |
| `scripts/_dsh-root.ps1` | 共享库：自动探测 DSH 安装目录、终止进程、日志函数 |
| `scripts/fix-crash-auto.ps1` | 换包（自动）：强杀 DSH → 改名 → 重启 → 自检 |
| `scripts/fix-crash-safe.ps1` | 换包（安全）：轮询等待你从托盘退出 → 改名 → 重启 |
| `scripts/rollback.ps1` | 回滚：`app.asar.bak` → `app.asar` |
| `scripts/*.cmd` | 三个双击入口，对应上面三个脚本 |
| `scripts/check-compat.mjs` | 环境自检：版本 / 解包状态 / 补丁数 / 是否需要换包 |
| `docs/compatibility.md` | 各 dsh 版本上的实测补丁命中情况 |
| `docs/troubleshooting-swap.md` | 崩溃与「补丁不生效」的完整排查路径 |
| `INSTALL.zh-CN.md` | 安装与验收步骤 |

### 变更

- `package.json`
  - `name`: `dsh-purge` → `dsh-purge-community`（避免与上游残留包名混淆）
  - `version`: `1.1.82` → `1.1.83`
  - `dshTarget`: `0.2.1-rc.2` → `0.2.2-rc.2`，新增 `dshTargetRange`
  - `repository` / `homepage` / `bugs` / `dsh.install.*`：指向本 fork
  - `contributors`：新增社区维护者字段
  - `files`：加入 `CHANGELOG.md`、`INSTALL.zh-CN.md`、`LICENSE-COMMERCIAL.md`
  - `scripts`：新增 `check:compat`

### 移除

- `_dump.mjs` / `_dump2.mjs`（上游调试残留）
- `lib/core.js.before-compat.bak`（本分支开发时的回滚备份，不随包发布）

### 未处理

以下补丁在 0.2.2-rc.2 上仍无法命中，原因是目标代码已被上游改写或删除：

`#54` `#56` `#60` `#62` `#77` `#80` `#71 preset-liangshen` `#83 desktop-shell`

它们不会导致崩溃，只会让对应的小功能保持原样。详见 `docs/compatibility.md`。

### 许可

本分支沿用上游 **Apache-2.0**。`NOTICE` 中的
`Copyright 2026 YuJunZhiXue` 与来源链接**保留原样**。
上游另有 `LICENSE-COMMERCIAL.md` 说明商业授权渠道，该文件同样原样保留。

---

## 上游最后版本 1.1.82

见 `release-notes.md`。上游作者于 2026-10-27 起停止在 GitHub 发布新版本。
