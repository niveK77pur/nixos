{
  lib,
  config,
  ...
}: let
  modname = "kernel";
  cfg = config.${modname};
in {
  options.${modname} = {
    enableSysRq = lib.mkEnableOption "SysRq";
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enableSysRq {
      boot.kernel.sysctl."kernel.sysrq" = 1;
    })
  ];
}
