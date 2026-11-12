# 换包失败排查：闪退 / 补丁不生效

## 一、先看现象属于哪一类

| 现象 | 判定 | 跳到 |
|---|---|---|
| 点「应用」后窗口整个消失，几秒后又起来 | `app.asar` 被强杀触发致命退出 | [§3](#3-为什么会闪退) |
| 能启动，但改过的界面/行为一个都没生效 | 补丁写好了，但运行时加载的仍是 `app.asar` | [§4](#4-为什么补丁不生效) |
| 启动脚本报 `app.asar still locked` | 文件被占用（进程没退干净 / 安全软件） | [§5](#5-文件被占用) |
| 启动后直接白屏或报模块找不到 | 切换成功但解包树不完整 | [§6](#6-解包树不完整) |

一条命令先把状态看清：

```bash
node scripts/check-compat.mjs
```

或者手写一版：

```bash
node scripts/check-compat.mjs "D:/deepseek"
```

## 二、背景：Electron 先加载谁

Electron 解析 `resources` 目录的顺序是**固定的**：

```
resources/app.asar        ← 文件存在就用它，优先级最高
resources/app             ← 目录，要被上面那个不存在才会轮到
resources/default_app.asar
```

插件的工作方式是：把 `app.asar` 解包成 `resources/app`，在目录树里打补丁，
**然后把 `app.asar` 改名成 `app.asar.bak`**，逼 Electron 去用目录树。

只要最后这步没成功，前面所有工作都是白做的 —— 补丁文件静静躺在
`resources/app` 里，运行时读的却是 `app.asar`。

## 三、为什么会闪退

原版 `resources/app.asar` 内的 `lib/main.js` 里，host 子进程的 `close` 事件是这么写的：

```js
child.once("close", (code, signal) => {
  const suffix = this.stderr.trim() === "" ? "" : `: ${this.stderr.trim()}`;
  if (code !== 0 && code !== null) this.fail(new Error(`dsh desktop host exited with ${code}${suffix}`));
  else this.fail(new Error(`dsh desktop host stopped${suffix}`));   // ← 无条件判死
});
```

**只要 host 退出（哪怕是被人 `Stop-Process` 杀掉的），整个桌面端就判定为致命并整体退出。**

而换包脚本需要先把 Electron 杀掉才能解锁 `app.asar` —— 于是一杀一个准，
杀完立刻触发上面的 `fail()`，用户看到的就是「点应用 → 闪退」。

补丁版把它改成：

```js
if (code === null || signal) { resolve(); return; }   // 被信号杀 → 静默
if (code !== 0) this.fail(...);                        // 只有真正非 0 退出才报警
resolve();
```

所以**换包成功之后**，这个闪退就不会再发生。闪退本身就是「还没换成功」的证据。

## 四、为什么补丁不生效

`check-compat.mjs` 输出这一行，就是在告诉你这件事：

```
resources/app          : 存在
resources/app.asar     : 存在（会抢先生效）
```

**asar 存在 = 补丁必不生效。** 直接跑 `scripts/fix-crash-auto.cmd`。

反过来的正常状态：

```
resources/app          : 存在
resources/app.asar     : 不存在
resources/app.asar.bak : 存在（原版已备份）
[OK] 状态: 已切换，运行时加载 resources/app（补丁生效）
```

## 五、文件被占用

报错长这样：

```
FAIL: app.asar still locked after 60s
```

三个原因，按概率排序：

### 1. 进程没退干净（最常见）

关窗口 ≠ 退出。DSH 常驻托盘，托盘里还有图标就说明主进程还活着。

- 用 `fix-crash-auto.cmd`：它会主动杀
- 或用 `fix-crash-safe.cmd`：提示你「右键托盘 → 退出」，然后自己检测解锁

### 2. 安全软件持有扫描句柄

360 系列的 `360rp` / `360rps` / `360sd` / `360tray` 会短暂甚至长期持有文件句柄，
并可能直接拦截「大文件改名」这个动作。

**处理**：360 → 木马查杀 → 信任区 → 添加目录 → 安装目录（如 `D:\deepseek`），
或临时关闭实时防护再跑一次。

### 3. 残留锁 / 半途中断

目录里可能留下：

- `app.asar.rename-pending` —— 上一次失败留下的标记
- `app.asar` 和 `app.asar.bak` 同时存在 —— 改到一半

处理：

```powershell
# 确认没有 DSH 进程后
Remove-Item -LiteralPath "D:\deepseek\resources\app.asar.rename-pending" -ErrorAction SilentlyContinue
```

然后重跑 `fix-crash-auto.cmd`。

## 六、解包树不完整

`fix-crash-*` 脚本开盘会校验三个必须存在的文件，缺任何一个就 `FATAL` 退出：

| 文件 | 作用 |
|---|---|
| `app/package.json` | Electron 靠它找入口 |
| `app/lib/main.js` | 主进程，含本次修复的 close 逻辑 |
| `app/dsh/node_modules/@deepseek-ai/dsh-desktop-host/lib/index.js` | host 入口 |

如果这里报缺失，说明解包没做完 —— 回 DSH 里重新点一次「应用」，再跑脚本。

## 七、怎么回滚

```
scripts/rollback.cmd
```

等价手动操作（确保 DSH 已退出）：

```powershell
Rename-Item "D:\deepseek\resources\app.asar.bak" "app.asar"
Start-Process "D:\deepseek\DeepSeek Harness.exe"
```

`resources\app` 目录不用删，留着不影响 —— 只要 `app.asar` 在，它就不会被加载。

## 八、崩溃日志在哪

```
%APPDATA%\@deepseek-ai\dsh-desktop\logs\crash-*.log
```

补丁/换包自身的过程日志（上游写的）：

```
%TEMP%\dsh-purge-desktop.log
```

崩溃日志里的 `stderr tail` **通常不是真凶**，它只是被杀那一刻缓冲区里剩下的最后几行。
真正的判据是进程退出方式（`signal` 还是 `code`），而这一点恰恰被原版逻辑一律当成致命。
