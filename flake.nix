{
  description = "A CAD modeling tool for artists";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "nixpkgs/nixos-23.11";
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };
        plasticity-bin-pkg = pkgs.callPackage ./pkg.nix {};
      in
      {
        packages = {
          inherit plasticity-bin-pkg;
          default = plasticity-bin-pkg;
        };

        apps = let
          plasticity = {
            type = "app";
            program = "${plasticity-bin-pkg}/bin/plasticity";
          };

        in {
          inherit plasticity;
          default = plasticity;
        };
      }
    );
}

