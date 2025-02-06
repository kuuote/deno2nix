{
  description = "Generate Nix expression for Deno vendoring";

  outputs =
    {
      nixpkgs,
      ...
    }:
    let
      forAllSystems =
        fn:
        nixpkgs.lib.genAttrs nixpkgs.lib.systems.flakeExposed (system: fn nixpkgs.legacyPackages.${system});
    in
    {
      devShells = forAllSystems (pkgs: rec {
        default = shell;
        shell = pkgs.mkShell {
          packages = [ pkgs.deno ];
        };
      });
      packages = forAllSystems (pkgs: {
        default = import ./. { inherit pkgs; };
      });
    };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };
}
