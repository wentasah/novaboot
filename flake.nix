{
  description = "novaboot";

  inputs = {
    nixpkgs.url = github:NixOS/nixpkgs/nixos-unstable;
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        novaboot = (import ./novaboot.nix { inherit self pkgs; });
        unfs3 = (import ./nix/unfs3.nix { inherit pkgs; });
      in {
        # Utilized by `nix build .`
        defaultPackage = novaboot.novaboot;

        packages.novaboot = novaboot.novaboot;
        packages.novaboot-server = novaboot.novaboot-server;
        packages.unfs3 = unfs3;

        devShell = pkgs.mkShell {
          inputsFrom = [
            (import ./novaboot.nix {
              inherit self pkgs;
              otherPerlPackages = [ pkgs.perl.pkgs.PodParser ];
            }).novaboot
          ];
          buildInputs = with pkgs; [
            syslinux
            cdrkit
            grub2
            dhcp
            unfs3
          ];
        };

        # Default overlay, for use in dependent flakes
        overlays = (final: prev: {
          inherit (novaboot) novaboot novaboot-server;
          inherit unfs3;
        });

        # Default module, for use in dependent flakes
        nixosModule = import ./nix/module.nix;

        # Same idea as nixosModule but a list or attrset of them.
        #nixosModules = { exampleModule = self.nixosModule; };
      }) // {
        nixosConfigurations.container = nixpkgs.lib.nixosSystem {
          system = flake-utils.lib.system.x86_64-linux;
          modules = [
            (import ./nix/module.nix)
            ({ pkgs, ... }: {

              nixpkgs.overlays = [ self.overlay.x86_64-linux ];

              boot.isContainer = true;

              # Let 'nixos-version --json' know about the Git revision
              # of this flake.
              system.configurationRevision = nixpkgs.lib.mkIf (self ? rev) self.rev;

              # Network configuration.
              networking.useDHCP = false;

              # Enable a web server.
              services.novaboot-server = {
                enable = true;
                accounts = {
                  novaboot-test = {
                    admins = {
                      sojka = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC1Ic+lRqxo0d+1+69Anoae4NXKGiVwiTL6GrHeXg9V2hEYCQdE1n6zaMjDtKnGmjW8a1NrG7C+2WepPxZ0WtKNJ0ixr7jx5VRd6Z4jFENPSsr9EXLhGQaRekRKTk9DoZnVK1SpAjHZvliK5EFX3i8aqMWD53LrWUGD7wabued30AGyTXmfUcMKT2dX94SOPGyTh7ygtXhpbuWGXA0ptxctFxsjRENkDbwcs2PNZhB6BKebNq4iI4xERJuppH1ODmG4N5wDxEXdzlPFZ2HfBnaUnuJ2w9ox/S2QjKzKidpDgwyGf63pXd+2DcvN4e3PJR4UpLAvgtbDmZr+mr016vt3 wsh-password-protected";
                    };
                  };
                  board2 = {};
                };
              };
            })
          ];
        };
      };
}
