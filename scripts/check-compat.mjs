#!/usr/bin/env node
/**
 * dsh-purge-community · 环境自检
 *
 * 用法:
 *   node scripts/check-compat.mjs                 # 自动探测安装目录
 *   node scripts/check-compat.mjs 'D:/deepseek'    # 指定 DSH 安装根目录
 *
 * 退出码: 0 = 一切正常 / 1 = 需要人处理 / 2 = 探测失败
 */
import { existsSync, readFileSync, readdirSync } from "node:fs";
import { join, dirname } from "node:path";
import { homedir } from "node:os";
import { fileURLToPath } from "node:url";

const HERE = dirname(fileURLToPath(import.meta.url));
const PKG = JSON.parse(readFileSync(join(HERE, "..", "package.json"), "utf8"));

const ESC = String.fromCharCode(27);
const paint = (code, s) => ESC + "[" + code + "m" + s + ESC + "[0m";
const C = {
  ok: (s) => paint("32", s),
  warn: (s) => paint("33", s),
  bad: (s) => paint("31", s),
  dim: (s) => paint("90", s),
  b: (s) => paint("1", s),
};

function findDshRoot() {
  const arg = process.argv[2];
  if (arg) return arg.split("\\").join("/");
  if (process.env.DSH_ROOT) return process.env.DSH_ROOT;
  const local = process.env.LOCALAPPDATA || join(homedir(), "AppData", "Local");
  const cands = [
    join(local, "Programs", "deepseek"),
    join(local, "Programs", "DeepSeek Harness"),
    "D:/deepseek",
    "C:/deepseek",
    join(process.env.ProgramFiles || "C:/Program Files", "DeepSeek Harness"),
  ];
  for (const c of cands) {
    if (c && existsSync(join(c, "DeepSeek Harness.exe"))) return c;
  }
  return null;
}

function dshVersion(root) {
  const appPkg = join(root, "resources", "app", "package.json");
  if (existsSync(appPkg)) {
    try { return JSON.parse(readFileSync(appPkg, "utf8")).version || null; } catch { /* ignore */ }
  }
  const upd = join(root, "resources", "app-update.yml");
  if (existsSync(upd)) {
    for (const raw of readFileSync(upd, "utf8").split("\n")) {
      const line = raw.trim();
      if (line.startsWith("version:")) return line.slice(8).trim();
    }
  }
  return null;
}

function countPatchBackups(appDir) {
  let n = 0;
  const walk = (d) => {
    let ents;
    try { ents = readdirSync(d, { withFileTypes: true }); } catch { return; }
    for (const e of ents) {
      const p = join(d, e.name);
      if (e.isDirectory()) walk(p);
      else if (e.name.endsWith(".dshpurge.bak")) n++;
    }
  };
  walk(appDir);
  return n;
}

const root = findDshRoot();
console.log(C.b("dsh-purge-community 环境自检"));
console.log(C.dim("------------------------------------------------------------"));

if (!root) {
  console.log(C.bad("[FAIL] 找不到 DeepSeek Harness 安装目录。"));
  console.log("       手工指定: node scripts/check-compat.mjs 'D:/deepseek'");
  process.exit(2);
}

const res = join(root, "resources");
const app = join(res, "app");
const asar = join(res, "app.asar");
const bak = join(res, "app.asar.bak");

const hasApp = existsSync(app);
const hasAsar = existsSync(asar);
const hasBak = existsSync(bak);

console.log("安装目录 : " + root);
console.log("插件版本 : " + PKG.version);
console.log("目标 dsh : " + PKG.dshTarget + "  " + C.dim("(" + (PKG.dshTargetRange || "") + ")"));

const ver = dshVersion(root);
if (ver) {
  const a = ver.split("-")[0].split(".").map(Number);
  const b = PKG.dshTarget.split("-")[0].split(".").map(Number);
  const good = a[0] === b[0] && a[1] === b[1];
  console.log("当前 dsh : " + ver + "  " + (good ? C.ok("兼容") : C.warn("未在目标范围内，补丁可能部分跳过")));
} else {
  console.log("当前 dsh : " + C.warn("无法读取版本"));
}

console.log(C.dim("------------------------------------------------------------"));
console.log("resources/app          : " + (hasApp ? C.ok("存在") : C.bad("缺失")));
console.log("resources/app.asar     : " + (hasAsar ? C.warn("存在（会抢先生效）") : C.ok("不存在")));
console.log("resources/app.asar.bak : " + (hasBak ? C.ok("存在（原版已备份）") : C.dim("不存在")));

if (!hasApp) {
  console.log("");
  console.log(C.bad("[FAIL] resources/app 不存在 —— 插件还没有解包过。"));
  console.log("       请先在 DSH 里启用插件并点一次「应用」。");
  process.exit(1);
}

const n = countPatchBackups(app);
console.log("已打补丁文件           : " + (n > 0 ? C.ok(String(n) + " 个 (.dshpurge.bak)") : C.bad("0 个")));

console.log(C.dim("------------------------------------------------------------"));

if (hasAsar && hasApp) {
  console.log(C.bad("[ACTION] 状态: 未切换"));
  console.log("  Electron 的加载顺序是 resources/app.asar 优先于 resources/app，");
  console.log("  所以补丁虽然打好了，但运行时加载的仍是原版 asar —— 补丁 0 生效。");
  console.log("");
  console.log("  解决: 退出 DeepSeek Harness（含托盘），然后在 scripts/ 里运行");
  console.log("        fix-crash-auto.cmd      (自动, 强杀后切换)");
  console.log("        fix-crash-safe.cmd      (安全, 等你手动退出托盘)");
  process.exit(1);
}

if (!hasAsar && hasBak) {
  console.log(C.ok("[OK] 状态: 已切换，运行时加载 resources/app（补丁生效）"));
  console.log("  注意: DSH 升级会重新铺回 app.asar，届时需要再跑一次切换脚本。");
  process.exit(0);
}

if (!hasAsar && !hasBak) {
  console.log(C.warn("[WARN] app.asar 与 app.asar.bak 都不存在。"));
  console.log("       若非你手动删除，请立即恢复备份，否则 DSH 无法启动。");
  process.exit(1);
}

console.log(C.warn("[WARN] 状态不明，请人工检查 resources 目录。"));
process.exit(1);
