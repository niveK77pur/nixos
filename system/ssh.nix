{
  lib,
  config,
  ...
}: let
  modname = "ssh";
  cfg = config.${modname};
in {
  options.${modname} = {
    enable = lib.mkEnableOption "${modname}";
  };

  config = lib.mkIf cfg.enable {
    services.openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
        X11Forwarding = true;
        PermitRootLogin = "no";
      };
    };
  };
}
