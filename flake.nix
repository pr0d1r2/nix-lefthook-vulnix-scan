{
  description = "CHANGEME";

  nixConfig = {
    extra-substituters = [ "https://pr0d1r2.cachix.org" ];
    extra-trusted-public-keys = [ "pr0d1r2.cachix.org-1:NfWjbhgAj41byXhCKiaE+av3Vnphm1fTezHXEGsiQIM=" ];
  };

  inputs = {
    nixpkgs-lock.url = "github:pr0d1r2/nixpkgs-lock";
    nixpkgs.follows = "nixpkgs-lock/nixpkgs";

    set-and-setting.url = "github:pr0d1r2/set-and-setting";

    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs =
    {
      self,
      nixpkgs,
      set-and-setting,
      nixpkgs-unstable,
      ...
    }:
    let
      forAllSystems =
        f: nixpkgs.lib.genAttrs supportedSystems (system: f nixpkgs.legacyPackages.${system});
          batsWithLibs = batsWithLibsFor pkgs;
    in
    set-and-setting.lib.mkConsumerFlake {
      inherit self nixpkgs set-and-setting;
      fragments = [
        "base"
        "nix"
        "shell"
        "ascii"
        "markdown"
        "yaml"
      ];
      extraPackages = pkgs: {
          default =
            let
              inherit (pkgs.stdenv.hostPlatform) system;
        devShells = forAllSystems (
          pkgs:
          let
            inherit (pkgs.stdenv.hostPlatform) system;
            batsWithLibs = batsWithLibsFor pkgs;
          in
          rec {
            default = pkgs.mkShell {
                self.packages.${system}.default
                batsWithLibs
                pkgs.coreutils
                pkgs.git
                pkgs.lefthook
                pkgs.markdownlint-cli
                pkgs.nix
                pkgs.parallel
              ]
              ++ (lefthookWrappersFor pkgs);
              shellHook = builtins.replaceStrings [ "@BATS_LIB_PATH@" ] [ "${batsWithLibs}" ] (
                builtins.readFile ./dev.sh
              );
            };
            ci = default;
          }
        );
      };
      src = ./.;
    };
}
