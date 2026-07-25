{
  description = "Lefthook-compatible vulnix scan";

  nixConfig = {
    extra-substituters = [ "https://pr0d1r2.cachix.org" ];
    extra-trusted-public-keys = [ "pr0d1r2.cachix.org-1:NfWjbhgAj41byXhCKiaE+av3Vnphm1fTezHXEGsiQIM=" ];
  };

  inputs = {
    nixpkgs-lock.url = "github:pr0d1r2/nixpkgs-lock";
    nixpkgs.follows = "nixpkgs-lock/nixpkgs";

    set-and-setting.url = "github:pr0d1r2/set-and-setting";

    nix-vulnix-nvd-mirror.url = "github:pr0d1r2/nix-vulnix-nvd-mirror";

    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs =
    {
      self,
      nixpkgs,
      nix-vulnix-nvd-mirror,
      set-and-setting,
      nixpkgs-unstable,
      ...
    }:
    let
      fragments = [
        "base"
        "nix"
        "shell"
        "ascii"
        "markdown"
        "yaml"
      ];
      consumer = set-and-setting.lib.mkConsumerFlake {
        inherit
          self
          nixpkgs
          set-and-setting
          fragments
          ;
        extraPackages =
          pkgs:
          let
            inherit (pkgs.stdenv.hostPlatform) system;
            vulnix = nixpkgs-unstable.legacyPackages.${system}.vulnix.overrideAttrs (old: {
              postPatch = (old.postPatch or "") + ''
                substituteInPlace src/vulnix/nvd.py \
                  --replace-fail \
                    'def update(self):' \
                    $'def update(self):\n        if os.environ.get("VULNIX_OFFLINE") == "1":\n            return'
                grep -q 'os.environ.get("VULNIX_OFFLINE")' src/vulnix/nvd.py
              '';
            });
            inherit (nix-vulnix-nvd-mirror.packages.${system}) nvd-cache;
          in
          {
            default = pkgs.writeShellApplication {
              name = "lefthook-vulnix-scan";
              runtimeInputs = [ vulnix ];
              runtimeEnv.VULNIX_CACHE_SOURCE = nvd-cache;
              text = builtins.readFile ./lefthook-vulnix-scan.sh;
            };
          };
        src = ./.;
      };
    in
    consumer
    // {
      # The locked mkConsumerFlake confirm app omits fragment wrappers from
      # PATH, although its coherence check requires them. Preserve the
      # upstream app while launching it with the materialized wrapper set.
      apps = nixpkgs.lib.mapAttrs (
        system: apps:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          materialization = set-and-setting.lib.materializationFor {
            inherit pkgs fragments;
          };
        in
        apps
        // {
          confirm = {
            type = "app";
            program = "${
              pkgs.writeShellApplication {
                name = "confirm-with-fragment-wrappers";
                runtimeInputs = materialization.packages;
                runtimeEnv.CONFIRM_PROGRAM = consumer.apps.${system}.confirm.program;
                text = builtins.readFile ./confirm-with-fragment-wrappers.sh;
              }
            }/bin/confirm-with-fragment-wrappers";
          };
        }
      ) consumer.apps;
    };
}
