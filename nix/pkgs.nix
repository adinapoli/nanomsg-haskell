{ pkgs ? import (if builtins.elem builtins.currentSystem ["x86_64-darwin" "aarch64-darwin"]
                 then ./pinned-25.05.darwin.nix
                 else ./pinned-25.05.nix) {} }:

rec {
  inherit pkgs;
  ghc966 = pkgs.haskell.compiler.ghc966;
  cabal_install = pkgs.haskell.lib.compose.justStaticExecutables pkgs.haskell.packages.ghc966.cabal-install;
  nng_notls = pkgs.nng.overrideAttrs (old: {
    cmakeFlags = (old.cmakeFlags or []) ++ [ "-DNNG_ENABLE_TLS=OFF" ];
  });
  hsBuildInputs = [
    ghc966
    cabal_install
    pkgs.haskellPackages.alex
    pkgs.haskellPackages.happy
    pkgs.haskellPackages.pretty-show
  ];
  nonhsBuildInputs = with pkgs; [
    nng_notls
    curl
  ] ++ ( lib.optionals stdenv.isDarwin [
       darwin.apple_sdk.frameworks.Accelerate
       ]);
  libPaths = pkgs.lib.makeLibraryPath nonhsBuildInputs;
  shellHook = ''
    export LD_LIBRARY_PATH="${pkgs.gfortran.cc.lib}:${libPaths}:$LD_LIBRARY_PATH"
    export LIBRARY_PATH="${pkgs.gfortran.cc.lib}:${libPaths}"
    export PATH="${pkgs.gccStdenv}/bin:$PATH"
    export NIX_CC="${pkgs.gccStdenv}"
    export CC="${pkgs.gccStdenv}/bin/gcc"
  '';
  shell = pkgs.mkShell.override { stdenv = pkgs.gccStdenv; } {
    name = "haskell-nng-shell";
    buildInputs = hsBuildInputs ++ nonhsBuildInputs;
    inherit shellHook;
  };
}
