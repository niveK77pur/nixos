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
    services = {
      openssh = {
        enable = true;
        settings = {
          PasswordAuthentication = false;
          KbdInteractiveAuthentication = false;
          X11Forwarding = true;
          PermitRootLogin = "no";
          MaxAuthTries = 3;
          PerSourcePenalties = lib.concatStringsSep " " [
            "authfail:3600s"
            "crash:3600s"
            "invaliduser:${5 * 60}s"
            "max:${24 * 3600}s"
          ];
        };
      };
      endlessh = {
        enable = true;
        port = 22;
        openFirewall = true;
      };
    };
  };
}
