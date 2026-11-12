# 安装（Windows · dsh 桌面版）

> 这是 **dsh-purge 的社区维护分支**，基于上游 `1.1.82`。
> 与上游最大的区别：**能用在 dsh 0.2.2-rc.2 上**，并且把「补丁打好了但不生效」这个坑堵上了。

---

## 0. 环境要求

| 项 | 要求 |
|---|---|
| 系统 | Windows 10 / 11 x64 |
| dsh | 桌面版，推荐 **0.2.2-rc.2** |
| Node | ≥ 18（dsh 自带的即可） |
| 磁盘 | 解包后 `resources/app` 约占 1 GB |

---

## 1. 安装（三种方式，任选其一）

### 方式 A：手动放入（最稳，推荐）

```powershell
# 1. 找到你的 dsh 插件目录（一般是这个）
$dest = "$env:USERPROFILE\.dsh\profiles\desktop\node_modules\dsh-purge-community"

# 2. 把本仓库解压到该目录（保证 package.json 直接位于 $dest 下）
#    最终结构应为：$dest\package.json、$dest\lib\、$dest\scripts\ ...

# 3. 校验
node "$dest\scripts\check-compat.mjs"
```

### 方式 B：tarball

```powershell
cd "$env:USERPROFILE\.dsh\profiles\desktop"
npm install "<本仓库的 tgz 或 codeload URL>"
```

### 方式 C：git clone

```powershell
cd "$env:USERPROFILE\.dsh\profiles\desktop\node_modules"
git clone https://github.com/<OWNER>/<REPO>.git dsh-purge-community
```

---

## 2. 启用插件

在 dsh 的插件配置里启用 `dsh-purge-community`（或按 `cordis.patch.yml` 挂载），
重启 dsh，确认设置面板里能看到插件的入口。

---

## 3. 点一次「应用」

进入插件面板 → 点「应用」。这一步会：

1. 把 `resources/app.asar` 解包到 `resources/app`
2. 在解包树里打约 56 个文件的补丁
3. 每个被改的文件旁边留一个 `*.dshpurge.bak`

> 首次解包 200 MB 级文件，耗时几分钟，属正常。

---

## 4. ⚠️ 关键一步：换包

**做完第 3 步，补丁仍然不会生效。** 因为 Electron 优先加载 `app.asar`。

必须让 `app.asar` 消失。进入本仓库的 `scripts/` 目录，二选一：

| 脚本 | 行为 | 适合 |
|---|---|---|
| `fix-crash-auto.cmd` | 强杀 dsh → 改名 → 自动重启 → 自检 | **推荐**，双击即可 |
| `fix-crash-safe.cmd` | 提示你从托盘退出手动退出，检测解锁后改名 | 不想被强杀 |

安全软件拦得住的话，先把安装目录加入 360 / 火绒的信任区。

---

## 5. 验收

```powershell
node scripts/check-compat.mjs
```

看到这三行就是好了：

```
resources/app          : 存在
resources/app.asar     : 不存在
resources/app.asar.bak : 存在（原版已备份）
[OK] 状态: 已切换，运行时加载 resources/app（补丁生效）
```

再补一条进程级确认（可选）：

```powershell
Get-CimInstance Win32_Process -Filter "Name='DeepSeek Harness.exe'" |
  Where-Object { $_.CommandLine -match 'renderer' } |
  ForEach-Object { if ($_.CommandLine -match '--app-path="([^"]+)"') { $Matches[1] } }
```

输出应为 `D:\deepseek\resources\app`（**不带 `.asar`**）。

---

## 6. ⚠️ dsh 升级之后

升级会重新铺回 `resources/app.asar`，补丁随即失效。升级完做两件事：

1. 插件面板点「应用」
2. 跑一次 `scripts/fix-crash-auto.cmd`

---

## 7. 卸载 / 回滚

| 目的 | 操作 |
|---|---|
| 只回滚换包 | `scripts/rollback.cmd` |
| 彻底还原 | 上一步 + 删掉 `resources/app` 目录 |
| 卸载插件 | 从 `node_modules` 移除 `dsh-purge-community` |

`resources\app` 留着不影响使用 —— 只要 `app.asar` 存在，它就不会被加载。

---

## 8. 出问题看这里

- [`docs/troubleshooting-swap.md`](docs/troubleshooting-swap.md) —— 闪退、补丁不生效、文件被占用
- [`docs/compatibility.md`](docs/compatibility.md) —— 你的 dsh 版本能命中多少补丁
- [`CHANGELOG.md`](CHANGELOG.md) —— 本分支改了什么

---

## 9. 许可与署名

Apache-2.0。原始作者 `YuJunZhiXue`（见 `NOTICE`），本分支为社区维护。
上游另有 `LICENSE-COMMERCIAL.md` 说明商业授权渠道，该文件原样保留。
