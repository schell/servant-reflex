{ reflex-platform, ... }:
let 
  pkgs = import <nixpkgs> {};
  c2n = reflex-platform.cabal2nixResult;
in reflex-platform.ghc.override {
  overrides = self: super: {
    servant-snap = pkgs.haskell.lib.dontCheck (self.callPackage (c2n deps/servant-snap) {});
    snap         = pkgs.haskell.lib.dontCheck (self.callPackage (c2n deps/servant-snap/deps/snap) {});
    snap-server  = pkgs.haskell.lib.dontCheck (self.callPackage (c2n deps/servant-snap/deps/snap/deps/snap-server) {});
    io-streams  = pkgs.haskell.lib.dontCheck (self.callPackage (c2n deps/servant-snap/deps/snap/deps/io-streams) {});
    io-streams-haproxy  = pkgs.haskell.lib.dontCheck (self.callPackage (c2n deps/servant-snap/deps/snap/deps/io-streams-haproxy) {});
    heist  = pkgs.haskell.lib.dontCheck (self.callPackage (c2n deps/servant-snap/deps/snap/deps/heist) {});
    xmlhtml  = pkgs.haskell.lib.dontCheck (self.callPackage (c2n deps/servant-snap/deps/snap/deps/xmlhtml) {});
    snap-core  = pkgs.haskell.lib.dontCheck (self.callPackage (c2n deps/servant-snap/deps/snap/deps/snap-core) {});
    servant  = pkgs.haskell.lib.dontCheck (self.callPackage (c2n deps/servant/servant) {});
    natural-transformation = self.callPackage (
      { mkDerivation, base, containers, fetchgit, quickcheck-instances
      , stdenv, tasty, tasty-quickcheck
      }:
      mkDerivation {
        pname = "natural-transformation";
        version = "0.4";
        src = fetchgit {
          url = "https://github.com/ku-fpg/natural-transformation";
          sha256 = "0xbnnxbf5ydszbhf7h5ra3mrqy4mcyqc3zb2k8bwm1zyqrz6v0fs";
          rev = "b1200c09dcafd034e32846413913b74735c8ba56";
        };
        libraryHaskellDepends = [ base ];
        testHaskellDepends = [
          base containers quickcheck-instances tasty tasty-quickcheck
        ];
        homepage = "https://github.com/ku-fpg/natural-transformation";
        description = "A natural transformation package";
        license = stdenv.lib.licenses.bsd3;
      }
      ) {};
    http-api-data = pkgs.haskell.lib.dontCheck (self.callPackage (c2n deps/http-api-data) {});
  };
}
