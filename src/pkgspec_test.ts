import { assertEquals } from "@std/assert";
import { parsePkgspec } from "./pkgspec.ts";

Deno.test({
  name: "parsePkgspec",
  fn() {
    {
      assertEquals(parsePkgspec("@std/json@1.0.0"), {
        name: "@std/json",
        version: "1.0.0",
      });
    }
  },
});
