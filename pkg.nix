{
  lib,
  stdenv,
  fetchurl,
  dpkg,
  makeWrapper,
  nodePackages,
  alsa-lib,
  openssl,
  at-spi2-atk,
  at-spi2-core,
  atk,
  cairo,
  cups,
  curl,
  dbus,
  expat,
  fontconfig,
  freetype,
  gdk-pixbuf,
  glib,
  gtk3,
  libGL,
  libappindicator-gtk3,
  libdrm,
  libnotify,
  libpulseaudio,
  libuuid,
  libxcb,
  libxkbcommon,
  mesa,
  nspr,
  nss,
  pango,
  pipewire,
  systemd,
  wayland,
  xdg-utils,
  xorg,
}:
# https://github.com/nkallen/plasticity/releases/download/v1.4.0-beta.26/plasticity-beta_1.4.0.beta.26_amd64.deb
# https://github.com/nkallen/plasticity/releases/download/v1.4.0-beta.26/plasticity_1.4.0.beta.26_amd64.deb
# https://github.com/nkallen/plasticity/releases/download/v1.4.0-beta.26/plasticity-beta_1.4.0.beta.26_amd64.deb
# https://github.com/nkallen/plasticity/releases/download/v1.4.0-beta.26/plasticity-beta-1.4.0.beta.26_amd64.deb
# https://github.com/nkallen/plasticity/releases/download/v1.4.0-beta.26/plasticity-beta_1.4.0.beta.26_amd64.deb
#      url = "${base}/releases/download/v${version}-beta.${betaVersion}/plasticity-beta-${version}-beta${betaVersion}_amd64.deb";
#
let
  inherit (stdenv.hostPlatform) system;
  throwSystem = throw "plasticity does not support system: ${system}";

  pname = "plasticity";
  version = "24.1.6";
  # version = "1.4.0";
  # hash = "sha256-o5d4l8tb+78fQhRxp8o2Xb1xCQtlUXwmLisAvbQuuq0=";
  # hash = lib.fakeHash;
  hash = "sha256-DIM3L9o/z2MZqrxPT64jS4c+s2fMApHs6xmDKDmcXGo=";
  # hash = "sha256-Y0zE8ILtzfSBVTZ5nVKlpe18Ct0Su7ocAHT7yfMtJK8=";
  # hash = "sha256-mPgRI+7WBFSN61ew3a0h2pddJMJEunmyvJfvqfyEpek=";
  # hash = "sha256-1Co2084V3ywDj7LOFT8KxFAmcdUQYPACYexQdbbZ/5E=";
  # hash = "sha256-l4TU+bWkgB5IA6hBVxSnRzaRmo3+VG8wYtITRjoa6u4=";
  binName = "plasticity";
  src = let
    base = "https://github.com/nkallen/plasticity";
  in
    {
      x86_64-linux = fetchurl {
        url = "${base}/releases/download/v${version}/plasticity_${version}_amd64.deb";
        # url = "${base}/releases/download/v${version}-beta.${betaVersion}/${binName}_${version}.beta.${betaVersion}_amd64.deb";
        inherit hash;
      };
    }
    .${system}
    or throwSystem;

  meta = with lib; {
    description = "CAD for artists";
    homepage = "https://www.plasticity.xyz/";
    sourceProvenance = with sourceTypes; [binaryNativeCode];
    license = licenses.gpl3;
    maintainers = with maintainers; [];
    platforms = ["x86_64-linux"];
  };
in
  stdenv.mkDerivation rec {
    inherit pname version src meta;
    rpath =
      lib.makeLibraryPath [
        alsa-lib
        at-spi2-atk
        at-spi2-core
        atk
        cairo
        cups
        curl
        dbus
        expat
        fontconfig
        freetype
        gdk-pixbuf
        glib
        gtk3
        libGL
        libappindicator-gtk3
        libdrm
        libnotify
        libpulseaudio
        libuuid
        libxcb
        libxkbcommon
        mesa
        nspr
        nss
        pango
        pipewire
        stdenv.cc.cc
        systemd
        wayland
        xorg.libX11
        xorg.libXScrnSaver
        xorg.libXcomposite
        xorg.libXcursor
        xorg.libXdamage
        xorg.libXext
        xorg.libXfixes
        xorg.libXi
        xorg.libXrandr
        xorg.libXrender
        xorg.libXtst
        xorg.libxkbfile
        xorg.libxshmfence
      ]
      + ":${stdenv.cc.cc.lib}/lib64";

    buildInputs = [
      gtk3 # needed for GSETTINGS_SCHEMAS_PATH
    ];

    nativeBuildInputs = [dpkg makeWrapper nodePackages.asar];

    dontUnpack = true;
    dontBuild = true;
    dontPatchELF = true;

    installPhase = ''
      runHook preInstall

      # dpkg -x can break some perms, e.g. setuid
      dpkg --fsys-tarfile $src | tar --extract
      rm -rf usr/share/lintian
      mkdir -p $out
      mv usr/* $out

      # Otherwise it looks "suspicious"
      chmod -R g-w $out

      for file in $(find $out -type f \( -perm /0111 -o -name \*.so\* \) ); do
        patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" "$file" || true
        patchelf --set-rpath ${rpath}:$out/lib/${binName} $file || true
      done

      # Replace the broken bin/plasticity symlink with a startup wrapper.
      # Make xdg-open overrideable at runtime.
      rm $out/bin/${binName}
      # was uppercase Plasticity for non-beta version
      makeWrapper $out/lib/${binName}/Plasticity $out/bin/${binName} \
        --prefix LD_LIBRARY_PATH : ${lib.getLib openssl}/lib \
        --prefix LD_LIBRARY_PATH : ${lib.getLib stdenv.cc.cc}/lib \
        --prefix XDG_DATA_DIRS : $GSETTINGS_SCHEMAS_PATH \
        --suffix PATH : ${lib.makeBinPath [xdg-utils]} \
        --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations,WebRTCPipeWireCapturer}}"

      # Fix the desktop link
      # substituteInPlace $out/share/applications/${binName}.desktop \
      #   --replace /usr/bin/ $out/bin/ \
      #   --replace /usr/share/pixmaps/plasticity.png plasticity \
      #   --replace bin/plasticity "bin/plasticity"

      runHook postInstall
    '';
  }
