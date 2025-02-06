import { fetchJsr, getPaths } from "./jsr.ts";
import { fetchMetaJson } from "./meta.ts";
import { is } from "@core/unknownutil";
import { type Pkgspec } from "./pkgspec.ts";

export async function nixHash(
  path: string,
  mode?: "path" | "file",
): Promise<string> {
  mode = mode ?? Deno.statSync(path).isDirectory ? "path" : "file";
  const output = await new Deno.Command("nix", {
    args: [
      "--extra-experimental-features",
      "nix-command",
      "hash",
      mode,
      path,
    ],
  }).output();
  return new TextDecoder().decode(output.stdout).trim();
}

function indent(str: string): string {
  return "  " + str;
}

export function objectToNixExpr(obj: unknown): string[] {
  if (is.Record(obj)) {
    const result = ["{"];
    for (const key of Object.keys(obj).sort()) {
      const subresult = objectToNixExpr(obj[key]);
      subresult[0] = `${JSON.stringify(key)} = ${subresult[0]}`;
      const last = subresult.length - 1;
      subresult[last] += ";";
      result.push(...subresult.map(indent));
    }
    result.push("}");
    return result;
  }
  if (is.Array(obj)) {
    const result = ["["];
    for (const subobj of obj) {
      result.push(...objectToNixExpr(subobj).map(indent));
    }
    result.push("]");
    return result;
  }
  return [JSON.stringify(obj)];
}

export async function generateNixExpr(
  pkgspec: Pkgspec,
  cacheRoot: string,
): Promise<string[]> {
  const { name, version } = pkgspec;
  const { meta, path, url } = await fetchMetaJson(pkgspec, cacheRoot);
  const metaHash = await nixHash(path);
  const jsrCache = await fetchJsr(pkgspec, meta, cacheRoot);
  const hash = await nixHash(jsrCache);
  return [
    "{",
    `  "jsr.io/${name}/meta.json" = builtins.toFile "meta.json" "{\\"versions\\": {}}";`,
    `  "jsr.io/${name}/${version}_meta.json" = builtins.fetchurl {`,
    `    url = "${url}";`,
    `    sha256 = "${metaHash}";`,
    "  };",
    `  "jsr.io/${name}/${version}" =`,
    `    runCommand "jsr:${name}@${version}"`,
    "      {",
    `        outputHash = "${hash}";`,
    '        outputHashAlgo = "sha256";',
    '        outputHashMode = "nar";',
    "      }",
    "      ''",
    "        export DENO_DIR=/tmp/deno",
    `        echo '{"vendor": true}' > deno.json`,
    ...getPaths(pkgspec, meta)
      .map((e) => `        \${deno}/bin/deno cache ${e}`),
    `        cp -a vendor/jsr.io/${pkgspec.name}/${pkgspec.version} $out`,
    "      '';",
    "}",
  ];
}
