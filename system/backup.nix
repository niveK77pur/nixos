{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.backup;
in {
  options.backup = {
    enable = lib.mkEnableOption "backup";
    locations = lib.mkOption {
      description = "The locations to be backed up";
      default = {};
      type = lib.types.attrsOf (lib.types.submodule ({
        name,
        config,
        ...
      }: {
        options = {
          path = lib.mkOption {
            type = lib.types.str;
            description = "The single path or btrfs subvolume to backup";
          };
          destinations = lib.mkOption {
            type = lib.types.attrsOf lib.types.str;
            default = {};
            description = "Borg destinations to backup the path";
          };
          borgOpts = lib.mkOption {
            type = lib.types.nullOr lib.types.attrs;
            default = null;
            description = "Options to configure `services.borgbackup.jobs.<name>`. Borg backups are disabled if not specified.";
          };
          snapperOpts = lib.mkOption {
            type = lib.types.nullOr lib.types.attrs;
            default = null;
            description = "Options to configure `services.snapper.configs.<name>`. Snapper backups are disabled if not specified.";
          };
          borgSnapshotPath = lib.mkOption {
            type = lib.types.str;
            default = "${config.path}/.borgbackup-snapshots/${name}";
            description = "Location to store the internal temporary btrfs snapshots";
          };
        };
      }));
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = lib.flatten (lib.mapAttrsToList (
        name: locCfg:
          (lib.optionals (locCfg.borgOpts != null) [
            {
              assertion = locCfg.destinations != {};
              message = "`backup.locations.${name}.destinations` must be given if `backup.locations.${name}.borgOpts` is given.";
            }
            {
              assertion = !(locCfg.borgOpts ? repo);
              message = "`backup.locations.${name}.borgOpts.repo` is managed by the backup module; set `backup.locations.${name}.destinations` instead.";
            }
            {
              assertion = !(locCfg.borgOpts ? paths);
              message = "`backup.locations.${name}.borgOpts.paths` is managed by the backup module; set `backup.locations.${name}.path` instead.";
            }
            {
              assertion = locCfg.borgOpts ? startAt;
              message = "`backup.locations.${name}.borgOpts.startAt` is required.";
            }
          ])
          ++ (lib.optionals (locCfg.snapperOpts != null) [
            {
              assertion = !(locCfg.snapperOpts ? SUBVOLUME);
              message = "`backup.locations.${name}.snapperOpts.SUBVOLUME` is managed by the backup module; set `backup.locations.${name}.path` instead.";
            }
          ])
      )
      cfg.locations);

    services.snapper = {
      persistentTimer = true;
      configs =
        lib.concatMapAttrs (
          group: locCfg:
            lib.optionalAttrs (locCfg.snapperOpts != null) {
              ${group} = locCfg.snapperOpts // {SUBVOLUME = locCfg.path;};
            }
        )
        cfg.locations;
    };

    services.borgbackup.jobs =
      lib.concatMapAttrs (
        group: locCfg:
          lib.optionalAttrs (locCfg.borgOpts != null) (
            lib.mapAttrs' (
              destname: destination:
                lib.nameValuePair "${group}-${destname}" (
                  locCfg.borgOpts
                  // {
                    # NOTE: We snapshot to `borgSnapshotPath` and `cd` into it
                    # so that borg archive entries are relative (./foo/bar.txt
                    # rather than /the/full/snapshot/path/foo/bar.txt). On
                    # restore: `cd /target && borg extract repo::archive`.
                    paths = ["."];
                    preHook =
                      (locCfg.borgOpts.preHook or "")
                      + ''
                        cd ${locCfg.borgSnapshotPath}
                      '';
                    repo = destination;
                    startAt = []; # Delegate starting to our custom systemd setup
                  }
                )
            )
            locCfg.destinations
          )
      )
      cfg.locations;

    systemd = lib.mkMerge [
      # Systemd options for borg
      (lib.foldl' lib.recursiveUpdate {} (lib.mapAttrsToList (
          group: locCfg: let
            runUnitName = "borg-run-${group}";
            prepareUnitName = "borg-prepare-${group}";
            cleanupUnitName = "borg-cleanup-${group}";
            borgbackupUnitName = destname: "borgbackup-job-${group}-${destname}";
            borgbackupJobUnits =
              map (destname: "${borgbackupUnitName destname}.service")
              (builtins.attrNames locCfg.destinations);
          in
            lib.optionalAttrs (locCfg.borgOpts != null) {
              targets.${runUnitName} = {
                description = "Borg backup run for ${group}";
                wants =
                  [
                    "${prepareUnitName}.service"
                    "${cleanupUnitName}.service"
                  ]
                  ++ borgbackupJobUnits;
              };

              timers.${runUnitName} = {
                description = "Borg backup timer for ${group}";
                wantedBy = ["timers.target"];
                timerConfig = {
                  Unit = "${runUnitName}.target";
                  Persistent = locCfg.borgOpts.persistentTimer or true;
                  OnCalendar = locCfg.borgOpts.startAt;
                };
              };

              services = let
                btrfs = lib.getExe pkgs.btrfs-progs;
              in
                {
                  ${prepareUnitName} = {
                    description = "Borg prepare snapshot for ${group}";
                    serviceConfig.Type = "oneshot";
                    partOf = ["${runUnitName}.target"];
                    script = ''
                      if ! ${btrfs} subvolume show ${locCfg.path} &>/dev/null; then
                        echo "ASSERTION: ${locCfg.path} must be a btrfs subvolume" >&2
                        exit 1
                      fi

                      mkdir -p "${dirOf locCfg.borgSnapshotPath}"

                      # Reclaim any orphan snapshot from a prior crashed run.
                      if [ -e "${locCfg.borgSnapshotPath}" ]; then
                        ${btrfs} subvolume delete ${locCfg.borgSnapshotPath}
                      fi

                      ${btrfs} subvolume snapshot -r ${locCfg.path} ${locCfg.borgSnapshotPath}
                    '';
                  };

                  ${cleanupUnitName} = {
                    description = "Borg cleanup snapshot for ${group}";
                    serviceConfig.Type = "oneshot";
                    after = ["${prepareUnitName}.service"] ++ borgbackupJobUnits;
                    script = ''
                      if [ -e "${locCfg.borgSnapshotPath}" ]; then
                        ${btrfs} subvolume delete ${locCfg.borgSnapshotPath}
                      fi
                    '';
                    # WARN: We must manually deactivate the target as systemd
                    # does not do this automatically when all its jobs complete.
                    # Failing to do this would render our backup pipeline stale.
                    # Cleanup is the last thing to run in our borgbackup
                    # pipeline, so this is the right place to mark the target as
                    # complete.
                    postStop = ''
                      ${pkgs.systemd}/bin/systemctl --no-block stop ${runUnitName}.target
                    '';
                  };
                }
                # Hook into and enhance services.borgbackup.jobs created module
                // lib.mapAttrs' (
                  destname: _:
                    lib.nameValuePair (borgbackupUnitName destname) {
                      serviceConfig.Type = "oneshot";
                      partOf = ["${runUnitName}.target"];
                      requires = ["${prepareUnitName}.service"];
                      after = ["${prepareUnitName}.service"];
                    }
                )
                locCfg.destinations;
            }
        )
        cfg.locations))
    ];
  };
}
