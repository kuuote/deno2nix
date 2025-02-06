import { fetchJsr } from "./jsr.ts";
import { fetchMetaJson } from "./meta.ts";
import { nixHash, objectToNixExpr } from "./nix.ts";
import { parsePkgspec } from "./pkgspec.ts";
import { stub } from "./stub.ts";

type DenoLock = {
  jsr: Record<string, unknown>;
  npm: Record<string, any>;
};

async function main(args: string[]): Promise<number> {
  const xdgCache = Deno.env.get("XDG_CACHE_HOME") ??
    `${Deno.env.get("HOME")}/.cache`;
  const cacheRoot = `${xdgCache}/deno2nix`;

  const lock = JSON.parse(await Deno.readTextFile(args[0])) as DenoLock;
  const jsr = [];
  for (const pkg of Object.keys(lock.jsr)) {
    const pkgspec = parsePkgspec(pkg)!;
    const { name, version } = pkgspec;
    const { meta, path } = await fetchMetaJson(pkgspec, cacheRoot);
    const jsrCache = await fetchJsr(pkgspec, meta, cacheRoot);
    const hash = await nixHash(jsrCache);
    jsr.push({
      name,
      version,
      exports: Object.keys(meta.exports).map((e) => e.slice(1)),
      hash: {
        meta: lock.jsr[pkg].integrity,
        src: hash,
      },
    });
  }
  const npm = structuredClone(lock.npm) ?? {};
  for (const spec of Object.keys(npm)) {
    const m = spec.match(/(@[^/]+\/)?([^@]+)@([^@]+)/)!;
    const path = (m[1] ?? "") + m[2];
    const name = m[2];
    const version = m[3];
    npm[spec].info = { path, name, version };
  }
  const result = {
    jsr,
    npm,
  };
  console.log(stub.trim() + " " + objectToNixExpr(result).join("\n"));
  return 0;
}

if (import.meta.main) {
  Deno.exit(await main(Deno.args));
}
