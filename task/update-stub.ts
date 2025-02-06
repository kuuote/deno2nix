const text = Deno.readTextFileSync("stub.nix");
const json = JSON.stringify(text);
const stub = `export const stub = ${json}`;
Deno.writeTextFileSync("src/stub.ts", stub);
