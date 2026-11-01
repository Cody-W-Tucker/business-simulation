{
  description = "Godot 4 3D starter";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { nixpkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      gdcef = pkgs.callPackage ./packages/gdcef/package.nix { };
      godotWithSharedCpp = pkgs.godot.overrideAttrs (old: {
        sconsFlags = old.sconsFlags ++ [ "use_static_cpp=no" "lto=none" ];
      });
      mkRoomShell = godot: enableCef: pkgs.mkShell {
        packages = [ godot ];
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
          echo "Godot 3D starter: run 'godot --editor' or 'godot --path .'"
        '';
      };
    in {
      packages.${system} = {
        inherit gdcef;
        godot-shared-cpp = godotWithSharedCpp;
      };
      devShells.${system} = {
        default = mkRoomShell godotWithSharedCpp true;
        gdcef = mkRoomShell godotWithSharedCpp true;
        preview = mkRoomShell pkgs.godot false;
      };
    };
}
