import fs from "fs";

const repos = [
  "w3cub/docshub-release-201704",
  "w3cub/docshub-release-201802",
  "w3cub/docshub-release-201902",
  "w3cub/w3cub-release-202001",
  "w3cub/w3cub-release-202011",
];

const latestRepo = "w3cub/w3cub-release-202603";

const BASE_URL = "https://docs.w3cub.com";

// 👉 建议加 token（否则很容易 rate limit）
const TOKEN = process.env.GITHUB_TOKEN || "";

async function fetchDirs(repo) {
  const url = `https://api.github.com/repos/${repo}/contents/?ref=gh-pages`;

  const res = await fetch(url, {
    headers: {
      Accept: "application/vnd.github+json",
      ...(TOKEN && { Authorization: `Bearer ${TOKEN}` }),
    },
  });

  if (!res.ok) {
    throw new Error(`❌ fetch failed: ${repo}`);
  }

  const data = await res.json();

  return data
    .filter((item) => item.type === "dir")
    .map((item) => item.name);
}

function compareVersion(a, b) {
  const pa = a.split(/[.-]/).map(Number);
  const pb = b.split(/[.-]/).map(Number);

  const len = Math.max(pa.length, pb.length);

  for (let i = 0; i < len; i++) {
    const na = pa[i] || 0;
    const nb = pb[i] || 0;

    if (na > nb) return 1;
    if (na < nb) return -1;
  }

  return 0;
}

// 👉 版本归一策略（你可以扩展）
function normalize(name, latestSet) {
  // 已存在 → 不处理
  if (latestSet.has(name)) return null;

  const match = name.match(/^(.+?)~(.+)$/);

  // ❗ 没有 ~ 的直接跳过
  if (!match) return null;

  const prefix = match[1];
  const version = match[2];

  // =========================
  // 🟢 情况1：存在“无版本主入口”
  // tensorflow → 存在
  // =========================
  if (latestSet.has(prefix)) {
    return prefix;
  }

  // =========================
  // 🟢 情况2：找最高版本
  // =========================
  const candidates = [...latestSet].filter((n) =>
    n.startsWith(prefix + "~")
  );

  if (!candidates.length) return null;

  candidates.sort((a, b) => {
    const va = a.split("~")[1];
    const vb = b.split("~")[1];
    return compareVersion(va, vb);
  });

  const latest = candidates[candidates.length - 1];

  if (latest === name) return null;

  return latest;
}

async function main() {
  console.log("🚀 获取最新版本列表...");
  const latestList = await fetchDirs(latestRepo);
  const latestSet = new Set(latestList);

  let redirects = [];

  for (const repo of repos) {
    console.log(`📦 处理 ${repo}...`);
    const list = await fetchDirs(repo);

    for (const item of list) {
      const target = normalize(item, latestSet);

      if (!target) continue;

      // 已存在 → 不需要
      if (latestSet.has(item)) continue;

      // 目标不存在 → 跳过
      if (!latestSet.has(target)) continue;

      if (item === target) continue;

      redirects.push({
        source: `${BASE_URL}/${item}`,
        target: `${BASE_URL}/${target}`,
      });
    }
  }

  // 去重
  const unique = Array.from(
    new Map(redirects.map((r) => [r.source, r])).values()
  );

  const lines = [
    "source,target,status_code,include_subdomains,subpath_matching,preserve_query_string,preserve_path_suffix",
  ];

  for (const r of unique) {
    lines.push(
      `${r.source},${r.target},301,true,true,true,true`
    );
  }

  fs.writeFileSync("redirects.csv", lines.join("\n"));

  console.log(`✅ 完成：${unique.length} 条`);
}

main();