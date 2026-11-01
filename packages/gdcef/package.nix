{ stdenv, lib, fetchurl, unzip, autoPatchelfHook, glib, nspr, nss, at-spi2-core
, dbus, cups, libx11, libxcomposite, libxdamage, libxext, libxfixes, libxrandr
, libgbm, libglvnd, expat, libxcb, libxkbcommon, cairo, pango, systemd, alsa-lib }:

stdenv.mkDerivation rec {
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
    runHook postInstall
  '';
  meta = {
    description = "Chromium Embedded Framework integration for Godot 4";
    homepage = "https://github.com/Lecrapouille/gdcef";
    license = lib.licenses.mit;
    platforms = [ "x86_64-linux" ];
  };
}
