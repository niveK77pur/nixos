{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.backup;

  btrfs = lib.getExe pkgs.btrfs-progs;
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

  config = lib.mkIf cfg.enable (lib.mkMerge (lib.flatten [
    {
      assertions = lib.flatten (lib.mapAttrsToList (name: locCfg: [
          {
            assertion = locCfg.borgOpts != null -> locCfg.destinations != {};
            message = "`backup.locations.${name}.destinations` must be given if `backup.locations.${name}.borgOpts` is given.";
          }
          {
            assertion = locCfg.borgOpts != null -> !(locCfg.borgOpts ? repo);
            message = "`backup.locations.${name}.borgOpts.repo` is managed by the backup module; set `backup.locations.${name}.destinations` instead.";
          }
          {
            assertion = locCfg.borgOpts != null -> !(locCfg.borgOpts ? paths);
            message = "`backup.locations.${name}.borgOpts.paths` is managed by the backup module; set `backup.locations.${name}.path` instead.";
          }
          {
            assertion = locCfg.borgOpts != null -> (locCfg.borgOpts ? startAt);
            message = "`backup.locations.${name}.borgOpts.startAt` is required.";
          }
          {
            assertion = locCfg.snapperOpts != null -> !(locCfg.snapperOpts ? SUBVOLUME);
            message = "`backup.locations.${name}.snapperOpts.SUBVOLUME` is managed by the backup module; set `backup.locations.${name}.path` instead.";
          }
        ])
        cfg.locations);
    }
    (lib.mapAttrsToList (group: locCfg: (lib.mkMerge (lib.flatten [
        (lib.mkIf (locCfg.snapperOpts != null) {
          services.snapper.configs.${group} = locCfg.snapperOpts // {SUBVOLUME = locCfg.path;};
        })

        (lib.mkIf (locCfg.borgOpts != null) (let
          runUnitName = "borg-run-${group}";
          prepareUnitName = "borg-prepare-${group}";
          cleanupUnitName = "borg-cleanup-${group}";
          borgbackupUnitName = destname: "borgbackup-job-${group}-${destname}";

          borgbackupJobUnits = map (destname: "${borgbackupUnitName destname}.service") (builtins.attrNames locCfg.destinations);
        in
          lib.mkMerge (lib.flatten [
            (lib.mapAttrsToList (destname: destination: {
                services.borgbackup.jobs."${group}-${destname}" =
                  locCfg.borgOpts
                  // {
                    # NOTE: This path should point to the btrfs snapshot instead.
                    # To avoid borg backups including the location to the btrfs
                    # snapshot, we shall `cd` into the snapshot so that the "root"
                    # of the backup is scoped to the folder to be backed up. This
                    # is a simple trick to avoid restoring backups into where btrfs
                    # snapshots would land. This is something minor/major to be
                    # aware of when restoring backups though.
                    paths = ["."];
                    preHook =
                      (locCfg.borgOpts.preHook or "")
                      + ''
                        cd ${locCfg.borgSnapshotPath}
                      '';
                    repo = destination;
                    startAt = []; # Delegate starting to our custom systemd setup
                  };

                # Hook into and enhance services.borgbackup.jobs created module
                systemd.services.${borgbackupUnitName destname} = {
                  serviceConfig.Type = "oneshot";
                  partOf = ["${runUnitName}.target"];
                  requires = ["${prepareUnitName}.service"];
                  after = ["${prepareUnitName}.service"];
                };
              })
              locCfg.destinations)

            {
              systemd = {
                targets."${runUnitName}" = {
                  description = "Borg backup run for ${group}";
                  wants = ["${prepareUnitName}.service" "${cleanupUnitName}.service"] ++ borgbackupJobUnits;
                };

                timers."${runUnitName}" = {
                  description = "Borg backup timer for ${group}";
                  wantedBy = ["timers.target"];
                  timerConfig = {
                    Unit = "${runUnitName}.target";
                    Persistent = locCfg.borgOpts.persistentTimer or true;
                    OnCalendar = locCfg.borgOpts.startAt;
                  };
                };

                services = {
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

                      # The snapshot path is meant for temporary snapshots;
                      # delete if one already exists here.
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
                    # does not do this automatically when all its jobs
                    # complete. Failing to do this would render our backup
                    # pipeline stale. The cleanup should be the last thing to
                    # run in our borgbackup pipeline, so this is the right
                    # place to mark the target as complete.
                    postStop = ''
                      ${pkgs.systemd}/bin/systemctl --no-block stop ${runUnitName}.target
                    '';
                  };
                };
              };
            }
          ])))
      ])))
      cfg.locations)
  ]));
}
