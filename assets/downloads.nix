{ pkgs }:
let
  poly = "https://dl.polyhaven.org/file/ph-assets";
  file = url: hash: pkgs.fetchurl { inherit url hash; };
  grass = pkgs.runCommand "grass001-color" { nativeBuildInputs = [ pkgs.unzip ]; } ''
    unzip -p ${file "https://ambientcg.com/get?file=Grass001_2K-JPG.zip" "sha256-pHVwB3tV8mCmxUiQpWAIfK/7nriyt4qE+CR7oZZtfR0="} Grass001_2K-JPG_Color.jpg > "$out"
    test -s "$out"
  '';
in {
  "assets/ambientcg-grass/Grass001_2K-JPG_Color.jpg" = grass;
  "assets/polyhaven-landscape/meadow_2_4k.hdr" = file "${poly}/HDRIs/hdr/4k/meadow_2_4k.hdr" "sha256-adL/SwkPDaTkzUtag/9+iY8IXbixjhy+nGJOV2D62WQ=";
  "assets/polyhaven-landscape/stone_floor_diff_4k.jpg" = file "${poly}/Textures/jpg/4k/stone_floor/stone_floor_diff_4k.jpg" "sha256-hVnB/+E1U/ihsCjjPX8Mtk2HiDp3MFLxm2kGtgiLfsQ=";
  "assets/polyhaven-landscape/stone_floor_nor_gl_4k.jpg" = file "${poly}/Textures/jpg/4k/stone_floor/stone_floor_nor_gl_4k.jpg" "sha256-uL8H5wYivEnk6S6FQpHPI0hbaPT0BPYrf1MPANFti/c=";
  "assets/polyhaven-landscape/white_sandstone_blocks_02_diff_1k.jpg" = file "${poly}/Textures/jpg/1k/white_sandstone_blocks_02/white_sandstone_blocks_02_diff_1k.jpg" "sha256-CkPIvIBYFAj5xwCtmNLeZCgOaUFI43Ym1mSP3d9Hp3c=";
  "assets/polyhaven-landscape/white_sandstone_blocks_02_nor_gl_1k.jpg" = file "${poly}/Textures/jpg/1k/white_sandstone_blocks_02/white_sandstone_blocks_02_nor_gl_1k.jpg" "sha256-FOsj4po0e5c5TGWm8f4sfBB9pVsY+5W5EscoDFpDty0=";
}
