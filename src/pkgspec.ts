export type Pkgspec = {
  name: string;
  version: string;
};

export function parsePkgspec(
  pkgspec: string,
): Pkgspec | undefined {
  const m = pkgspec.match("(@[^/]+/[^@]+)@(.*)");
  if (m == null) {
    return;
  }
  return {
    name: m[1],
    version: m[2],
  };
}
