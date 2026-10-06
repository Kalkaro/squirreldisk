{
  description = "SquirrelDisk disk usage analyzer";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { nixpkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
      pname = "squirreldisk";
      version = "2.5.0";

      src = pkgs.fetchurl {
        url = "https://github.com/adileo/squirreldisk/releases/download/v${version}/SquirrelDisk-x86_64.AppImage";
        hash = "sha256-Aj4iYnXEZOwcS3ZCxAnYnkmPTsM4SaPgsn1CKzuWFhM=";
      };

      appimageContents = pkgs.appimageTools.extract {
        inherit pname version src;
      };

      squirreldisk = pkgs.appimageTools.wrapType2 {
        inherit pname version src;

        # Match xkbcommon to the X11 Compose data provided by the Nix environment.
        profile = ''
          export LD_LIBRARY_PATH="${
            pkgs.lib.makeLibraryPath [ pkgs.libxkbcommon ]
          }''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
        '';

        extraInstallCommands = ''
          install -Dm444 ${appimageContents}/squirreldisk.desktop \
            $out/share/applications/squirreldisk.desktop
          substituteInPlace $out/share/applications/squirreldisk.desktop \
            --replace-fail 'Exec=squirreldisk' "Exec=$out/bin/squirreldisk"

          install -Dm444 ${appimageContents}/squirreldisk.png \
            $out/share/icons/hicolor/256x256/apps/squirreldisk.png
        '';

        meta = {
          description = "See what's using your disk space and clean it up";
          homepage = "https://github.com/adileo/squirreldisk";
          license = pkgs.lib.licenses.agpl3Only;
          mainProgram = pname;
          platforms = [ system ];
          sourceProvenance = [ pkgs.lib.sourceTypes.binaryNativeCode ];
        };
      };

      app = {
        type = "app";
        program = "${squirreldisk}/bin/squirreldisk";
        meta.description = squirreldisk.meta.description;
      };
    in
    {
      packages.${system} = {
        inherit squirreldisk;
        default = squirreldisk;
      };

      apps.${system} = {
        squirreldisk = app;
        default = app;
      };

      checks.${system}.squirreldisk = squirreldisk;
      formatter.${system} = pkgs.nixfmt;
    };
}
