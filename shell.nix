{ pkgs ? import <nixpkgs> {} }:
with pkgs;
mkShell {
  inputsFrom = [
    (import ./default.nix {
      inherit pkgs;
      otherPerlPackages = [ perl.pkgs.PodParser ];
    }).novaboot
  ];
}
