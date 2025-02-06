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
build {
  "jsr" = [
    {
      "exports" = [
        ""
        "/as"
        "/as/optional"
        "/as/readonly"
        "/assert"
        "/ensure"
        "/is"
        "/is/any"
        "/is/array"
        "/is/array-of"
        "/is/async-function"
        "/is/bigint"
        "/is/boolean"
        "/is/custom-jsonable"
        "/is/function"
        "/is/instance-of"
        "/is/intersection-of"
        "/is/jsonable"
        "/is/literal-of"
        "/is/literal-one-of"
        "/is/map"
        "/is/map-of"
        "/is/null"
        "/is/nullish"
        "/is/number"
        "/is/object-of"
        "/is/omit-of"
        "/is/parameters-of"
        "/is/partial-of"
        "/is/pick-of"
        "/is/primitive"
        "/is/readonly-of"
        "/is/record"
        "/is/record-object"
        "/is/record-object-of"
        "/is/record-of"
        "/is/required-of"
        "/is/set"
        "/is/set-of"
        "/is/strict-of"
        "/is/string"
        "/is/symbol"
        "/is/sync-function"
        "/is/tuple-of"
        "/is/undefined"
        "/is/uniform-tuple-of"
        "/is/union-of"
        "/is/unknown"
        "/maybe"
        "/type"
      ];
      "hash" = {
        "meta" = "538a3687ffa81028e91d148818047df219663d0da671d906cecd165581ae55cc";
        "src" = "sha256-dgURpViMnyECxY/06ZMUtlUICVcoesHrTBGlSNgsgVQ=";
      };
      "name" = "@core/unknownutil";
      "version" = "4.3.0";
    }
    {
      "exports" = [
        ""
        "/assert"
        "/almost-equals"
        "/array-includes"
        "/equals"
        "/exists"
        "/false"
        "/greater"
        "/greater-or-equal"
        "/instance-of"
        "/is-error"
        "/less"
        "/less-or-equal"
        "/match"
        "/unstable-never"
        "/not-equals"
        "/not-instance-of"
        "/not-match"
        "/not-strict-equals"
        "/object-match"
        "/rejects"
        "/strict-equals"
        "/string-includes"
        "/throws"
        "/assertion-error"
        "/equal"
        "/fail"
        "/unimplemented"
        "/unreachable"
      ];
      "hash" = {
        "meta" = "2461ef3c368fe88bc60e186e7744a93112f16fd110022e113a0849e94d1c83c1";
        "src" = "sha256-8Qiu6f61lq5PGjnxrmr0tlYi3gGavzIEoSdwsv5PVLc=";
      };
      "name" = "@std/assert";
      "version" = "1.0.11";
    }
    {
      "exports" = [
        ""
        "/copy"
        "/empty-dir"
        "/ensure-dir"
        "/ensure-file"
        "/ensure-link"
        "/ensure-symlink"
        "/eol"
        "/exists"
        "/expand-glob"
        "/move"
        "/unstable-chmod"
        "/unstable-link"
        "/unstable-lstat"
        "/unstable-read-dir"
        "/unstable-read-link"
        "/unstable-real-path"
        "/unstable-stat"
        "/unstable-symlink"
        "/unstable-types"
        "/walk"
      ];
      "hash" = {
        "meta" = "ba674672693340c5ebdd018b4fe1af46cb08741f42b4c538154e97d217b55bdd";
        "src" = "sha256-GmGW4/pJDh0SvtdAo41UHQFjMi+GEoN73v/EbBMkhTg=";
      };
      "name" = "@std/fs";
      "version" = "1.0.11";
    }
    {
      "exports" = [
        ""
        "/assertion-state"
        "/build-message"
        "/diff-str"
        "/diff"
        "/format"
        "/styles"
        "/types"
      ];
      "hash" = {
        "meta" = "54a546004f769c1ac9e025abd15a76b6671ddc9687e2313b67376125650dc7ba";
        "src" = "sha256-8tbW4Y7GzRvsP7FqkFO73uVCo3y6gaJRSohCbFMYdSk=";
      };
      "name" = "@std/internal";
      "version" = "1.0.5";
    }
    {
      "exports" = [
        ""
        "/basename"
        "/common"
        "/constants"
        "/dirname"
        "/extname"
        "/format"
        "/from-file-url"
        "/glob-to-regexp"
        "/is-absolute"
        "/is-glob"
        "/join"
        "/join-globs"
        "/normalize"
        "/normalize-glob"
        "/parse"
        "/posix"
        "/posix/basename"
        "/posix/common"
        "/posix/constants"
        "/posix/dirname"
        "/posix/extname"
        "/posix/format"
        "/posix/from-file-url"
        "/posix/glob-to-regexp"
        "/posix/is-absolute"
        "/posix/is-glob"
        "/posix/join"
        "/posix/join-globs"
        "/posix/normalize"
        "/posix/normalize-glob"
        "/posix/parse"
        "/posix/relative"
        "/posix/resolve"
        "/posix/to-file-url"
        "/posix/to-namespaced-path"
        "/posix/unstable-basename"
        "/posix/unstable-dirname"
        "/posix/unstable-extname"
        "/posix/unstable-join"
        "/posix/unstable-normalize"
        "/relative"
        "/resolve"
        "/to-file-url"
        "/to-namespaced-path"
        "/types"
        "/unstable-basename"
        "/unstable-dirname"
        "/unstable-extname"
        "/unstable-join"
        "/unstable-normalize"
        "/windows"
        "/windows/basename"
        "/windows/common"
        "/windows/constants"
        "/windows/dirname"
        "/windows/extname"
        "/windows/format"
        "/windows/from-file-url"
        "/windows/glob-to-regexp"
        "/windows/is-absolute"
        "/windows/is-glob"
        "/windows/join"
        "/windows/join-globs"
        "/windows/normalize"
        "/windows/normalize-glob"
        "/windows/parse"
        "/windows/relative"
        "/windows/resolve"
        "/windows/to-file-url"
        "/windows/to-namespaced-path"
        "/windows/unstable-basename"
        "/windows/unstable-dirname"
        "/windows/unstable-extname"
        "/windows/unstable-join"
        "/windows/unstable-normalize"
      ];
      "hash" = {
        "meta" = "548fa456bb6a04d3c1a1e7477986b6cffbce95102d0bb447c67c4ee70e0364be";
        "src" = "sha256-pEVka8u1JvEzTMlPD3U8FgG2rqp4Ao+3ggUFO4MAcA0=";
      };
      "name" = "@std/path";
      "version" = "1.0.8";
    }
  ];
  "npm" = {
  };
}
