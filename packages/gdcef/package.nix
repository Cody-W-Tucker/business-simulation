{ stdenv, lib, fetchurl, unzip, autoPatchelfHook, glib, nspr, nss, at-spi2-core
, dbus, cups, libx11, libxcomposite, libxdamage, libxext, libxfixes, libxrandr
, libgbm, libglvnd, expat, libxcb, libxkbcommon, cairo, pango, systemd, alsa-lib
, cmake, ninja, scons, python3, patchelf }:

let
  # Rebuild the Godot extension for native period input and dynamic frame rates;
  # keep the matching CEF runtime and render subprocess from upstream.
  browser = stdenv.mkDerivation {
    pname = "gdcef-browser";
    version = "0.21.0";
    src = fetchurl {
      url = "https://github.com/Lecrapouille/gdcef/archive/refs/tags/v0.21.0-godot4.tar.gz";
      hash = "sha256-My579kevqk1ee/i5FH2OeRw/vo+Tra3EzPPm+I8X2Ww=";
    };
    godotCpp = fetchurl {
      url = "https://github.com/godotengine/godot-cpp/archive/refs/tags/10.0.0-stable.tar.gz";
      hash = "sha256-679k8Pj4uLZrxLxNN5fbl/lbGc8N+1s/jPVmg9nffbQ=";
    };
    cef = fetchurl {
      url = "https://cef-builds.spotifycdn.com/cef_binary_156.0.14%2Bg4fa4ab5%2Bchromium-156.0.8078.48_linux64_minimal.tar.bz2";
      hash = "sha256-QZGskgqRoFLroEr7btgw1HrtRqPiRsQ0ovBiwjWI3Io=";
    };
    patches = [ ./period-key.patch ];
    nativeBuildInputs = [ cmake ninja scons python3 patchelf ];
    dontConfigure = true;
    buildPhase = ''
      runHook preBuild
      mkdir -p thirdparty/godot-cpp thirdparty/cef_binary out
      tar xf "$godotCpp" -C thirdparty/godot-cpp --strip-components=1
      tar xf "$cef" -C thirdparty/cef_binary --strip-components=1
      cmake -S thirdparty/cef_binary -B thirdparty/cef_binary/build -G Ninja \
        -DCMAKE_BUILD_TYPE=Release -DPROJECT_ARCH=x86_64 -DUSE_SANDBOX=OFF
      cmake --build thirdparty/cef_binary/build --target libcef_dll_wrapper -j "$NIX_BUILD_CORES"
      (cd thirdparty/godot-cpp && scons platform=linux target=template_release \
        api_version=4.7 -j "$NIX_BUILD_CORES")
      (cd gdcef/browser && scons platform=linux target=release \
        api_path="$PWD/../../thirdparty/godot-cpp" build_path="$PWD/../../out" \
        cef_artifacts_folder="$PWD/../../out" -j "$NIX_BUILD_CORES")
      runHook postBuild
    '';
    installPhase = ''
      install -Dm755 out/libgdcef.so "$out/libgdcef.so"
      patchelf --set-rpath '$ORIGIN' "$out/libgdcef.so"
    '';
  };
in stdenv.mkDerivation rec {
  pname = "gdcef";
  version = "0.21.0";
  src = fetchurl {
    url = "https://github.com/Lecrapouille/gdcef/releases/download/v${version}-godot4/gdcef-${version}_godot-4.7.zip";
    hash = "sha256-3hScg6vcnFrjSXo+NR9sHzzSbF057NQ6Fc6hE+T8FrM=";
  };
  nativeBuildInputs = [ unzip autoPatchelfHook ];
  buildInputs = [ glib nspr nss at-spi2-core dbus cups libx11 libxcomposite
    libxdamage libxext libxfixes libxrandr libgbm expat libxcb libxkbcommon
    cairo pango systemd alsa-lib stdenv.cc.cc.lib ];
  dontUnpack = true;
  dontStrip = true;
  runtimeDependencies = [ libglvnd ];
  installPhase = ''
    runHook preInstall
    mkdir -p "$out"
    unzip -q "$src" 'gdcef/cef_artifacts/linux/*' 'gdcef/cef_artifacts/gdcef.gdextension' 'gdcef/cef_artifacts/LICENSE' -d "$TMPDIR/unpacked"
    cp -a "$TMPDIR/unpacked/gdcef/cef_artifacts/." "$out/"
    chmod +x "$out/linux/gdCefRenderProcess"
    cp ${browser}/libgdcef.so "$out/linux/libgdcef.so"
    runHook postInstall
  '';
  meta = {
    description = "Chromium Embedded Framework integration for Godot 4";
    homepage = "https://github.com/Lecrapouille/gdcef";
    license = lib.licenses.mit;
    platforms = [ "x86_64-linux" ];
  };
}
