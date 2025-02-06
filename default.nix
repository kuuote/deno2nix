{
  pkgs ? import <nixpkgs> { },
}:
let
  config = pkgs.linkFarm "config" {
    "deno.json" = ./deno.json;
    "deno.lock" = ./deno.lock;
    "vendor" = (import ./deno.nix { inherit pkgs; }).vendor;
  };
  mkScript =
    { name, src }:
    pkgs.writeShellScriptBin name ''${pkgs.deno}/bin/deno run --allow-env --allow-read --allow-net=jsr.io --allow-write --allow-run -c ${config}/deno.json --vendor=true --cached-only ${./.}${src} "$@" '';
in
rec {
  default = deno2nix;
  deno2nix = mkScript {
    name = "deno2nix";
    src = "/src/main.ts";
  };
}
