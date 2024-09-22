self:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.hardware.usbdm;
  defaultPackage = self.packages.${pkgs.stdenv.hostPlatform.system}.default;
in
{
  options.hardware.usbdm = {
    enable = lib.mkEnableOption "Whether or not to enable USBDM.";
    package = lib.mkOption {
      type = with lib.types; nullOr package;
      default = defaultPackage;
    };

    udev = lib.mkEnableOption "Whether to add the udev rules for USBDM.";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];
    services.udev.packages = lib.mkIf cfg.udev [ cfg.package ];
  };
}
