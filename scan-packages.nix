# Wrapper packages for the vulnix scan hook.
#
# withCache bakes the mirror's pinned NVD cache in as a build-time dependency.
# That makes the wrapper unbuildable whenever the mirror's feed hashes drift,
# even for consumers that scan through the mirror and never read the cache, so
# `default` leaves it out and the script falls back to the mirror. `offline`
# keeps the baked cache for air-gapped use.
{
  pkgs,
  unstable,
  nvdCache,
  script,
}:

let
  patchedVulnix = unstable.vulnix.overrideAttrs (old: {
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
  });

  mkScan =
    { withCache }:
    pkgs.writeShellApplication {
      name = "lefthook-vulnix-scan";
      runtimeInputs = [ patchedVulnix ];
      runtimeEnv = pkgs.lib.optionalAttrs withCache { VULNIX_CACHE_SOURCE = nvdCache; };
      text = builtins.readFile script;
    };
in
{
  default = mkScan { withCache = false; };
  offline = mkScan { withCache = true; };
}
