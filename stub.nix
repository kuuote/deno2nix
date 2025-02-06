{
  pkgs ? import <nixpkgs> { },
}:
let
  inherit (pkgs)
    lib
    deno
    ;
  fetchJsr =
    {
      name,
      version,
      exports,
      hash,
    }:
    {
      "jsr.io/${name}/meta.json" = builtins.toFile "meta.json" "{\"versions\": {}}";
      "jsr.io/${name}/${version}_meta.json" = builtins.fetchurl {
        url = "https://jsr.io/${name}/${version}_meta.json";
        sha256 = hash.meta;
      };
      "jsr.io/${name}/${version}" =
        pkgs.runCommand "jsr:${name}@${version}"
          {
            outputHash = hash.src;
            outputHashAlgo = "sha256";
            outputHashMode = "nar";
            inherit exports;
          }
          ''
            export DENO_DIR=/tmp/deno
            echo '{"vendor": true}' > deno.json
            xargs ${lib.getExe deno} cache << EOS
            ${lib.pipe exports [
              (map (e: "jsr:${name}@${version}/${e}"))
              (builtins.concatStringsSep "\n")
            ]}
            EOS
            cp -a vendor/jsr.io/${name}/${version} $out
          '';
    };
  buildVendorDir =
    data:
    lib.pipe data.jsr [
      (map fetchJsr)
      lib.mergeAttrsList
      (pkgs.linkFarm "vendor")
    ];
  fetchNpm =
    m:
    let
      tgz = pkgs.fetchurl {
        url = "https://registry.npmjs.org/${m.info.path}/-/${m.info.name}-${m.info.version}.tgz";
        hash = m.integrity;
      };
    in
    pkgs.runCommandLocal "npm:${m.info.path}@${m.info.version}" { } ''
      mkdir dist
      cd dist
      tar xf ${tgz}
      mkdir -p $out/node_modules/${m.info.path}
      cp -a */* $out/node_modules/${m.info.path}/
      ln -s ${tgz} $out/node_modules/${m.info.path}/_archive.tgz
    '';
  buildNodeModules =
    data:
    let
      modules = builtins.mapAttrs (_: m: m // { src = fetchNpm m; }) data.npm;
      withoutVersion = lib.mapAttrs' (_: m: {
        name = m.info.path;
        value = m;
      }) modules;
      findDeps =
        m:
        map (d: modules.${d} or withoutVersion.${d}) (
          [ "${m.info.path}@${m.info.version}" ] ++ m.dependencies or [ ]
        );
      genPaths =
        mod:
        let
          plusName = builtins.replaceStrings [ "/" ] [ "+" ] "${mod.info.path}@${mod.info.version}";
        in
        lib.pipe mod [
          findDeps
          (map (m: {
            name = ".deno/${plusName}/node_modules/${m.info.path}";
            path = "${m.src}/node_modules/${m.info.path}";
          }))
        ];
    in
    lib.pipe modules [
      builtins.attrValues
      (map genPaths)
      builtins.concatLists
      (pkgs.linkFarm "node_modules")
    ];
  build = data: {
    nodeModules = buildNodeModules data;
    vendor = buildVendorDir data;
  };
in
build
