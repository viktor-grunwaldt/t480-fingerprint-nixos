{
  description = "Provides packages, modules and functions for the 06cb:009a fingerprint sensor.";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs =
    {
      self,
      nixpkgs,
    }:
    let
      fixups = final: prev: {
        libfprint-tod = prev.libfprint-tod.overrideAttrs (old: rec {
          version = "1.90.7+git20210222+tod1";
          src = old.src.overrideAttrs {
            rev = "v${version}";
            outputHash = "0cj7iy5799pchyzqqncpkhibkq012g3bdpn18pfb19nm43svhn4j";
            outputHashAlgo = "sha256";
          };
          buildInputs = (old.buildInputs or [ ]) ++ [ final.nss ];
          mesonFlags = [
            "-Ddrivers=all"
            "-Dudev_hwdb_dir=${placeholder "out"}/lib/udev/hwdb.d"
          ];
        });
      };
      pkgs = import nixpkgs {
        system = "x86_64-linux";
        overlays = [ fixups ];
      };
      localPackages = import ./pkgs/default.nix { pkgs = pkgs; };
      localLib = import ./lib {
        pkgs = pkgs;
        localPackages = localPackages;
      };
    in
    {
      nixosModules.python-validity =
        args:
        import ./modules/python-validity (
          args
          // {
            localPackages = localPackages;
          }
        );

      nixosModules.open-fprintd = ./modules/open-fprintd;

      nixosModules."06cb-009a-fingerprint-sensor" =
        args:
        import ./modules/06cb-009a-fingerprint-sensor (
          args
          // {
            localPackages = localPackages;
            libfprint-2-tod1-vfs0090-bingch = localLib.libfprint-2-tod1-vfs0090-bingch;
          }
        );
    };
}
