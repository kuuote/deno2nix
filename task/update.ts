try {
  Deno.removeSync("deno.lock");
} catch {
  // ignore error
}
const denoJson = JSON.parse(Deno.readTextFileSync("deno.json"));
const imps = Object.values(denoJson.imports)
  .map((i) => {
    const m = String(i).match(/jsr:@[a-z-].+\/[a-z-]+/);
    return m == null ? null : m[0];
  })
  .filter((i) => i != null);
await new Deno.Command("deno", {
  args: [
    "add",
    ...imps,
  ],
}).spawn().status;
