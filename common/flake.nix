{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs = { self, nixpkgs }: let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
  in {
    packages.${system}.default = pkgs.stdenvNoCC.mkDerivation rec {
      pname = "context-standalone";
      version = import ./version;
      src = self;
      nativeBuildInputs = [ pkgs.makeWrapper ];
      dontConfigure = true;
      dontBuild = true;
      installPhase = ''
        # symlink "modules" -> "modules"
        mkdir -p $out
        ln -s ${src}/modules $out/modules

        # symlink "tex/*" -> "tex/*"
        mkdir -p $out/tex
        for FILE in ${src}/tex/*; do
          ln -s $FILE $out/tex/''${FILE##*/}
        done

        # copy "tex/texmf-linux-64" -> "tex/texmf-linux-64"
        rm $out/tex/texmf-linux-64
        cp -a ${src}/tex/texmf-linux-64 $out/tex/texmf-linux-64

        # wrap "tex/texmf-linux-64/bin/<exe>" -> "bin/<exe>"
        for FILE in $(find $out/tex/texmf-linux-64/bin -type f -executable -follow); do
          makeWrapper $FILE $out/bin/''${FILE##*/}
        done
      '';
      preFixup = let
        libPath = pkgs.lib.makeLibraryPath [ pkgs.glibc ];
      in ''
        patchelf \
          --set-interpreter "${pkgs.glibc}/lib64/ld-linux-x86-64.so.2" \
          --set-rpath "${libPath}" \
          $out/tex/texmf-linux-64/bin/luametatex $out/tex/texmf-linux-64/bin/luatex
      '';
      postFixup = ''
        # generate file databases
        $out/bin/mtxrun --generate
        $out/bin/luatex --luaonly $out/tex/texmf-linux-64/bin/mtxrun.lua --generate
      '';
    };
  };
}
