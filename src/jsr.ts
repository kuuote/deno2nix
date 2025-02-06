import { copy } from "@std/fs/copy";
import { type Meta } from "./meta.ts";
import { type Pkgspec } from "./pkgspec.ts";

export function getPaths(pkgspec: Pkgspec, meta: Meta): string[] {
  return Object.keys(meta.exports)
    .map((e) => `jsr:${pkgspec.name}@${pkgspec.version}${e.slice(1)}`);
}

export async function fetchJsr(
  pkgspec: Pkgspec,
  meta: Meta,
  cacheRoot: string,
): Promise<string> {
  const { name, version } = pkgspec;
  const cacheDir = `${cacheRoot}/jsr/src/${name}`;
  const cachePath = `${cacheDir}/${version}`;
  try {
    await Deno.stat(cachePath);
    return cachePath;
  } catch {
    // do nothing
  }
  console.error(`fetch: ${name}/${version}`);
  const tempDir = await Deno.makeTempDir();
  try {
    const novendor = `${tempDir}/novendor.json`;
    const vendor = `${tempDir}/vendor.json`;
    await Deno.writeTextFile(novendor, '{"vendor":false}');
    await Deno.writeTextFile(vendor, '{"vendor":true}');
    const paths = getPaths(pkgspec, meta);
    await new Deno.Command("deno", {
      args: [
        "cache",
        "-c",
        novendor,
        ...paths,
      ],
    }).spawn().status;
    const status = await new Deno.Command("deno", {
      args: [
        "cache",
        "-c",
        vendor,
        ...paths,
      ],
    }).spawn().status;
    if (!status.success) {
      throw `cache fail: ${status.code}`;
    }
    await Deno.mkdir(cacheDir, { recursive: true });
    await copy(`${tempDir}/vendor/jsr.io/${name}/${version}`, cachePath);
  } finally {
    await Deno.remove(tempDir, { recursive: true });
  }
  return cachePath;
}
