{
  description = "Godot 4 3D starter";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.godot-ai = {
    url = "github:hi-godot/godot-ai/35da2c2fe1e2c20e11b5be01841e966951d6314b";
    flake = false;
  };

  outputs = { nixpkgs, godot-ai, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      gdcef = pkgs.callPackage ./packages/gdcef/package.nix { };
      downloadedAssets = import ./assets/downloads.nix { inherit pkgs; };
      setupAssets = pkgs.lib.concatStringsSep "\n" (pkgs.lib.mapAttrsToList (path: source: ''
        asset=${pkgs.lib.escapeShellArg path}
        source=${pkgs.lib.escapeShellArg (toString source)}
        mkdir -p "$(dirname "$asset")" || exit 1
        if [ -e "$asset" ] || [ -L "$asset" ]; then
          if ! cmp -s "$source" "$asset"; then
            echo "Asset conflict: $asset differs from the pinned download; move it aside and re-enter nix develop." >&2
            exit 1
          fi
        else
          ln -s "$source" "$asset" || exit 1
        fi
      '') downloadedAssets);
      godotWithSharedCpp = pkgs.godot.overrideAttrs (old: {
        sconsFlags = old.sconsFlags ++ [ "use_static_cpp=no" "lto=none" ];
      });
      godotAiUvx = pkgs.writeShellScriptBin "uvx" ''
        exec ${pkgs.uv}/bin/uvx --python ${pkgs.python3}/bin/python3 "$@"
      '';
      godotAiAttach = pkgs.writeShellApplication {
        name = "godot-ai-attach";
        runtimeInputs = [ godotAiUvx ];
        text = ''
          export GODOT_AI_DISABLE_TELEMETRY=true
          exec uvx --isolated --no-config --no-env-file --no-sources --no-build \
            --index-strategy first-index --keyring-provider disabled \
            --index https://pypi.org/simple --default-index https://pypi.org/simple \
            --find-links https://pypi.org/simple/godot-ai/ --link-mode copy \
            --from godot-ai==4.3.1 godot-ai attach --port 8000 --ws-port 9500
        '';
      };
      mkRoomShell = godot: enableCef: pkgs.mkShell {
        packages = [ godot godotAiUvx pkgs.uv ];
        shellHook = pkgs.lib.optionalString enableCef ''
          export ROOM_ENABLE_GDCEF=1
          export LD_LIBRARY_PATH="${pkgs.libglvnd}/lib:/run/opengl-driver/lib''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
          if [ ! -e cef_artifacts ] && [ ! -L cef_artifacts ]; then
            ln -s ${gdcef} cef_artifacts
          elif [ -L cef_artifacts ]; then
            case "$(readlink cef_artifacts)" in
              /nix/store/*-gdcef-*) ln -sfn ${gdcef} cef_artifacts ;;
            esac
          fi
        '' + ''
          export GODOT_AI_DISABLE_TELEMETRY=true
          mkdir -p addons
          if [ ! -e addons/godot_ai ] && [ ! -L addons/godot_ai ]; then
            ln -s ${godot-ai}/plugin/addons/godot_ai addons/godot_ai
          elif [ "$(readlink addons/godot_ai)" != "${godot-ai}/plugin/addons/godot_ai" ]; then
            echo "Godot AI addon conflict: addons/godot_ai already exists; leaving it untouched." >&2
          fi
          mkdir -p assets/_scratch || exit 1
          ${setupAssets}
          echo "Godot 3D starter: run 'godot --editor' or 'godot --path .'"
        '';
      };
    in {
      packages.${system} = {
        inherit gdcef;
        godot-ai-mcp = godotAiAttach;
        godot-shared-cpp = godotWithSharedCpp;
      };
      devShells.${system} = {
        default = mkRoomShell godotWithSharedCpp true;
        gdcef = mkRoomShell godotWithSharedCpp true;
        preview = mkRoomShell pkgs.godot false;
      };
    };
}
