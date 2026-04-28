{
  description = "Lefthook-compatible vulnix scan";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-lefthook-git-conflict-markers = {
      url = "github:pr0d1r2/nix-lefthook-git-conflict-markers";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-lefthook-git-no-local-paths = {
      url = "github:pr0d1r2/nix-lefthook-git-no-local-paths";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-lefthook-missing-final-newline = {
      url = "github:pr0d1r2/nix-lefthook-missing-final-newline";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-lefthook-nix-no-embedded-shell = {
      url = "github:pr0d1r2/nix-lefthook-nix-no-embedded-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-lefthook-trailing-whitespace = {
      url = "github:pr0d1r2/nix-lefthook-trailing-whitespace";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-cavemem = {
      url = "github:pr0d1r2/nix-cavemem";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-lefthook-statix = {
      url = "github:pr0d1r2/nix-lefthook-statix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        nix-lefthook-git-conflict-markers.follows = "nix-lefthook-git-conflict-markers";
        nix-lefthook-git-no-local-paths.follows = "nix-lefthook-git-no-local-paths";
        nix-lefthook-missing-final-newline.follows = "nix-lefthook-missing-final-newline";
        nix-lefthook-trailing-whitespace.follows = "nix-lefthook-trailing-whitespace";
      };
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-unstable,
      nix-lefthook-git-conflict-markers,
      nix-lefthook-git-no-local-paths,
      nix-lefthook-missing-final-newline,
      nix-lefthook-nix-no-embedded-shell,
      nix-lefthook-trailing-whitespace,
      nix-cavemem,
      nix-lefthook-statix,
    }:
    let
      supportedSystems = [
        "aarch64-darwin"
        "x86_64-darwin"
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems =
        f: nixpkgs.lib.genAttrs supportedSystems (system: f nixpkgs.legacyPackages.${system});
    in
    {
      packages = forAllSystems (pkgs: {
        default = pkgs.writeShellApplication {
          name = "lefthook-vulnix-scan";
          runtimeInputs = [ nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system}.vulnix ];
          text = builtins.readFile ./lefthook-vulnix-scan.sh;
        };
      });

      devShells = forAllSystems (
        pkgs:
        let
          batsWithLibs = pkgs.bats.withLibraries (p: [
            p.bats-support
            p.bats-assert
            p.bats-file
          ]);
        in
        {
          default = pkgs.mkShell {
            packages = [
              self.packages.${pkgs.stdenv.hostPlatform.system}.default
              nix-lefthook-git-conflict-markers.packages.${pkgs.stdenv.hostPlatform.system}.default
              nix-lefthook-git-no-local-paths.packages.${pkgs.stdenv.hostPlatform.system}.default
              nix-lefthook-missing-final-newline.packages.${pkgs.stdenv.hostPlatform.system}.default
              nix-lefthook-nix-no-embedded-shell.packages.${pkgs.stdenv.hostPlatform.system}.default
              nix-lefthook-trailing-whitespace.packages.${pkgs.stdenv.hostPlatform.system}.default
              nix-lefthook-statix.packages.${pkgs.stdenv.hostPlatform.system}.default
              nix-cavemem.packages.${pkgs.stdenv.hostPlatform.system}.default
              batsWithLibs
              pkgs.coreutils
              pkgs.deadnix
              pkgs.editorconfig-checker
              pkgs.git
              pkgs.lefthook
              pkgs.nix
              pkgs.nixfmt
              pkgs.parallel
              pkgs.shellcheck
              pkgs.shfmt
              pkgs.typos
              pkgs.nodejs
              pkgs.yamllint
            ];
            shellHook = builtins.replaceStrings [ "@BATS_LIB_PATH@" ] [ "${batsWithLibs}" ] (
              builtins.readFile ./dev.sh
            );
          };
        }
      );
    };
}
