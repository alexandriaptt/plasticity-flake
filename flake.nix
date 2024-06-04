{
  description = "A CAD modeling tool for artists";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "nixpkgs/nixos-24.05";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = import nixpkgs {
          inherit system;
        };
        plasticity-pkg = pkgs.callPackage ./pkg.nix {};
      in {
        packages = {
          plasticity = plasticity-pkg;
          default = plasticity-pkg;
        };

        apps = let
          plasticity = {
            type = "app";
            program = "${plasticity-pkg}/bin/plasticity";
          };
        in {
          inherit plasticity;
          default = plasticity;
        };
      }
    );
}
