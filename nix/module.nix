# Module, that replace novaboot-adduser on declarative NixOS systems
{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.services.novaboot-server;
in
{
  options = {
    services.novaboot-server = with types; {
      enable = mkEnableOption "Novaboot server";

      accounts = mkOption {
        description = "User accounts to configure with novaboot-shell";
        example = [
          ''[ "board1" "board2" ]''
        ];
        type = attrsOf (submodule {
          options = {
            admins = mkOption {
              description = "Admin users and their SSH public keys";
              type = attrsOf singleLineStr;
              default = {};
              example = ''
                {
                  johndoe = "ssh-ed25519 AAAAC3NzaCetcetera/etceteraJZMfk3QPfQ john@doe";
                }
              '';
            };
            users = mkOption {
              description = "Normal users and their SSH public keys";
              type = attrsOf singleLineStr;
              default = {};
              example = ''
                {
                  johndoe = "ssh-ed25519 AAAAC3NzaCetcetera/etceteraJZMfk3QPfQ john@doe";
                }
              '';
            };
          };
        });
      };
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ novaboot-server unfs3 ];
    services.openssh.enable = true;
    services.tftpd.enable = true;
    systemd.packages = with pkgs; [ novaboot-server unfs3 ];

    users.users = mapAttrs (name: value: {
      group = "novaboot";
      autoSubUidGidRange = true;
      isNormalUser = true;
      shell = "${pkgs.novaboot-server}/bin/novaboot-shell";
      openssh.authorizedKeys.keys =
        mapAttrsToList (user: key: ''command="user ${user} admin" ${key}'') (value.admins or {}) ++
        mapAttrsToList (user: key: ''command="user ${user}" ${key}'') (value.users or {});
    }) cfg.accounts;
    system.activationScripts.novaboot-server = stringAfter [ "users" ]
      (''
         install -d -m 0755 /srv/tftp
       '' +
      (concatStringsSep "\n"
        (mapAttrsToList
          (account: value: ''
            install -d -m 0755 -o ${account} /home/${account}/tftproot
            ln -sfn /home/${account}/tftproot /srv/tftp/${account}
            ln -sfn /home/${account}
          '')
          cfg.accounts)));
  };
}
