{ lib
, mkDerivation
, fetchFromGitHub
, makeDesktopItem
, substituteAll
, fetchpatch
, cmake
, jdk8
, jdk
, zlib
, file
, makeWrapper
, xorg
, libpulseaudio
, qtbase
, libGL
# submodules
, self
, submoduleNbt
, submoduleQuazip
, msaClientID ? ""
}:

let
  gameLibraryPath = with xorg; lib.makeLibraryPath [
    libX11
    libXext
    libXcursor
    libXrandr
    libXxf86vm
    libpulseaudio
    libGL
  ];
in

mkDerivation rec {
  pname = "polymc";
  version = "nightly";

  src = lib.cleanSource self;

  nativeBuildInputs = [ cmake file makeWrapper ];
  buildInputs = [ qtbase jdk8 zlib ];

  postUnpack = ''
    mkdir libraries/{libnbtplusplus,quazip}
    cp -a ${submoduleNbt}/* libraries/libnbtplusplus
    cp -a ${submoduleQuazip}/* libraries/quazip
  '';
  
  postPatch = ''
    # add client ID
    substituteInPlace notsecrets/Secrets.cpp \
      --replace 'QString MSAClientID = "";' 'QString MSAClientID = "${msaClientID}";'
  '';

  cmakeFlags = [
    "-DLauncher_LAYOUT=lin-system"
  ];

  desktopItem = makeDesktopItem {
    name = "polymc";
    exec = "polymc";
    icon = "polymc";
    desktopName = "PolyMC";
    genericName = "Minecraft Launcher";
    comment = "A custom launcher for Minecraft";
    categories = "Game;";
    extraEntries = ''
      Keywords=game;Minecraft;
    '';
  };

  postInstall = ''
    install -Dm644 ../launcher/resources/multimc/scalable/launcher.svg $out/share/pixmaps/multimc.svg
    install -Dm755 ${desktopItem}/share/applications/polymc.desktop -t $out/share/applications
    # xorg.xrandr needed for LWJGL [2.9.2, 3) https://github.com/LWJGL/lwjgl/issues/128
    wrapProgram $out/bin/polymc \
      --set GAME_LIBRARY_PATH /run/opengl-driver/lib:${gameLibraryPath} \
      --prefix PATH : ${lib.makeBinPath [ xorg.xrandr jdk ]}
  '';
}
