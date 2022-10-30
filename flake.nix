{
  description = "novaboot";

  inputs = {
    # The nixpkgs entry in the flake registry.
    nixpkgs.url = github:NixOS/nixpkgs/nixos-unstable;
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        novaboot = (import ./novaboot.nix { inherit self pkgs; });
      in {
        # Utilized by `nix build .`
        defaultPackage = novaboot.novaboot;

        packages.novaboot = novaboot.novaboot;
        packages.novaboot-server = novaboot.novaboot_server;

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
            bats
          ];
        };

        # Default overlay, for use in dependent flakes
        overlay = final: prev: { };

        # Default module, for use in dependent flakes
        #nixosModule = { config, ... }: { options = {}; config = {}; };

        # Same idea as nixosModule but a list or attrset of them.
        #nixosModules = { exampleModule = self.nixosModule; };
      });
}
