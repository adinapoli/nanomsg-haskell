{
  description = "nanomsg-haskell (built against nng's nanomsg compatibility layer)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/21454c534a05a2e6a5819898b457ff31b2becbdc";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        hsPkgs = pkgs.haskellPackages;
        # nixpkgs' nng is built with TLS, leaving mbedtls symbols undefined
        # when the bindings link against its static library. The bindings
        # don't use TLS, so disable it (same trick as nix/pkgs.nix).
        nng = pkgs.nng.overrideAttrs (old: {
          cmakeFlags = (old.cmakeFlags or []) ++ [ "-DNNG_ENABLE_TLS=OFF" ];
        });
        # nixpkgs' default tasty (1.4.3) predates sequentialTestGroup, which
        # the test suite uses; build the tests against the 1.5 series and
        # rebuild tasty-quickcheck against it so both agree on one tasty.
        tasty = hsPkgs.tasty_1_5_2;
        tasty-quickcheck = pkgs.haskell.lib.dontCheck
          (hsPkgs.tasty-quickcheck_0_11.override { inherit tasty; });
        nanomsg-haskell = hsPkgs.callCabal2nix "nanomsg-haskell" ./. {
          inherit nng tasty tasty-quickcheck;
        };
      in
      {
        devShells.default = pkgs.mkShell {
          packages = [
            nng
            hsPkgs.ghc
            hsPkgs.cabal-install
          ];
        };

        packages = rec {
          default = nanomsg-haskell;
        };

        checks = {
          default = pkgs.haskell.lib.overrideCabal nanomsg-haskell (drv: {
            doCheck = true;
          });
        };
      }
    );
}
