import { type Pkgspec } from "./pkgspec.ts";

export type Meta = {
  exports: Record<string, string>;
};

export type MetaInfo = {
  data: Uint8Array;
  meta: Meta;
  path: string;
  url: string;
};

export async function fetchMetaJson(
  pkgspec: Pkgspec,
  cacheRoot: string,
): Promise<MetaInfo> {
  const { name, version } = pkgspec;
  const metaJsonPath = `${name}/${version}_meta.json`;
  const cachePath = `${cacheRoot}/jsr/meta/${metaJsonPath}`;
  const url = `https://jsr.io/${metaJsonPath}`;
  try {
    const data = await Deno.readFile(cachePath);
    const meta = JSON.parse(new TextDecoder().decode(data)) as Meta;
    return {
      data,
      meta,
      path: cachePath,
      url,
    };
  } catch {
    // do nothing
  }
  console.error(`fetch: ${metaJsonPath}`);
  const data = await fetch(`https://jsr.io/${metaJsonPath}`)
    .then((r) => r.bytes());
  const meta = JSON.parse(new TextDecoder().decode(data)) as Meta;
  try {
    await Deno.mkdir(`${cacheRoot}/meta/${name}`, { recursive: true });
    await Deno.writeFile(cachePath, data);
  } catch {
    console.error(`cache write failed: ${cachePath}`);
  }
  return {
    data,
    meta,
    path: cachePath,
    url,
  };
}
