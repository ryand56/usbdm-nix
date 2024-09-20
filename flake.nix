{
  description = "USBDM support for Nix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs =
    inputs@{ self, flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "i686-linux"
        "x86_64-darwin"
      ];

      flake = {
        nixosModules =
          let
            default = import ./nixos-module.nix self;
          in
          {
            inherit default;
            usbdm = default;
          };
      };

      perSystem =
        { pkgs, ... }:
        let
          usbdm = pkgs.callPackage ./pkgs/usbdm { };
        in
        {
          formatter = pkgs.nixfmt-rfc-style;

          packages = {
            default = usbdm;
            inherit usbdm;
          };
        };
    };
}
