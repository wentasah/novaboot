{ pkgs ? import <nixpkgs> {} }:
with pkgs;
mkShell {
  inputsFrom = [
    (import ./default.nix {
      inherit pkgs;
      otherPerlPackages = [ perl.pkgs.PodParser ];
    }).novaboot
  ];
  buildInputs = with pkgs; [
    syslinux
    cdrkit
    grub2
    dhcp
  ];
}
