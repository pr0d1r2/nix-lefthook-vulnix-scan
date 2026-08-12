{
  description = "Lefthook-compatible vulnix scan";

  nixConfig = {
    extra-substituters = [ "https://pr0d1r2.cachix.org" ];
    extra-trusted-public-keys = [ "pr0d1r2.cachix.org-1:NfWjbhgAj41byXhCKiaE+av3Vnphm1fTezHXEGsiQIM=" ];
  };

  inputs = {
    nixpkgs-lock.url = "github:pr0d1r2/nixpkgs-lock";
    nixpkgs.follows = "nixpkgs-lock/nixpkgs";

    set-and-setting = {
      url = "github:pr0d1r2/set-and-setting";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nixpkgs-lock.follows = "nixpkgs-lock";
    };

    nix-vulnix-nvd-mirror.url = "github:pr0d1r2/nix-vulnix-nvd-mirror";
    nix-vulnix-nvd-mirror.inputs.nixpkgs.follows = "nixpkgs";

    nixpkgs-unstable.follows = "nixpkgs";
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
    set-and-setting.lib.mkConsumerFlake {
      inherit
        self
        nixpkgs
        set-and-setting
        ;
      fragments = [
        "base"
        "actions"
        "nix"
        "shell"
        "ascii"
        "markdown"
        "yaml"
      ];
      extraPackages = pkgs: {
        default = pkgs.writeShellApplication {
          name = "lefthook-vulnix-scan";
          runtimeInputs = [
            (nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system}.vulnix.overrideAttrs (old: {
              postPatch = (old.postPatch or "") + ''
                # Keep live-mirror fallback tolerant of slow responses.
                substituteInPlace src/vulnix/nvd.py \
                  --replace-fail 'timeout=10)' 'timeout=60)'
                substituteInPlace src/vulnix/nvd.py \
                  --replace-fail \
                    'def update(self):' \
                    $'def update(self):\n        if os.environ.get("VULNIX_OFFLINE") == "1":\n            return'
                grep -q 'timeout=60)' src/vulnix/nvd.py
                grep -q 'os.environ.get("VULNIX_OFFLINE")' src/vulnix/nvd.py
              '';
            }))
          ];
          runtimeEnv.VULNIX_CACHE_SOURCE =
            nix-vulnix-nvd-mirror.packages.${pkgs.stdenv.hostPlatform.system}.nvd-cache;
          text = builtins.readFile ./lefthook-vulnix-scan.sh;
        };
      };
      src = ./.;
    }
    // {
      # The locked mkConsumerFlake confirm app omits fragment wrappers from
      # PATH, although its coherence check requires them. Preserve the
      # upstream app while launching it with the materialized wrapper set.
      apps =
        nixpkgs.lib.mapAttrs
          (
            system: apps:
            apps
            // {
              confirm = {
                type = "app";
                program = "${
                  nixpkgs.legacyPackages.${system}.writeShellApplication {
                    name = "confirm-with-fragment-wrappers";
                    runtimeInputs =
                      (set-and-setting.lib.materializationFor {
                        pkgs = nixpkgs.legacyPackages.${system};
                        fragments = [
                        "base"
                        "actions"
                        "nix"
                          "shell"
                          "ascii"
                          "markdown"
                          "yaml"
                        ];
                      }).packages;
                    runtimeEnv.CONFIRM_PROGRAM = apps.confirm.program;
                    text = builtins.readFile ./confirm-with-fragment-wrappers.sh;
                  }
                }/bin/confirm-with-fragment-wrappers";
              };
            }
          )
          (set-and-setting.lib.mkConsumerFlake {
            inherit self nixpkgs set-and-setting;
            fragments = [
              "base"
              "actions"
              "nix"
              "shell"
              "ascii"
              "markdown"
              "yaml"
            ];
            src = ./.;
          }).apps;
    };
}
