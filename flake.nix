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
      extraPackages =
        pkgs:
        let
          inherit (pkgs.stdenv.hostPlatform) system;
          # vulnix hardcodes a 10s read timeout on the NVD-archive download.
          # Keep the existing guarded override so a slow mirror does not cause
          # a false-negative scan failure.
          vulnix = nixpkgs-unstable.legacyPackages.${system}.vulnix.overrideAttrs (old: {
            postPatch = (old.postPatch or "") + ''
              substituteInPlace src/vulnix/nvd.py \
                --replace 'timeout=10)' 'timeout=60)'
              grep -q 'timeout=60)' src/vulnix/nvd.py
            '';
          });
        in
        {
          default = pkgs.writeShellApplication {
            name = "lefthook-vulnix-scan";
            runtimeInputs = [ vulnix ];
            text = builtins.readFile ./lefthook-vulnix-scan.sh;
          };
        };
      src = ./.;
    };
}
