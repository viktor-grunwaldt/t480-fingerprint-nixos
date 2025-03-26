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
        # can be removed when https://github.com/NixOS/nixpkgs/pull/389711 is merged (it won't be)
        # follow https://github.com/NixOS/nixpkgs/pull/388905 for the current status
        libfprint = prev.libfprint.overrideAttrs (oldAttrs: {
          buildInputs = oldAttrs.buildInputs ++ [ prev.nss ];
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
