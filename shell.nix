{ pkgs ? import <nixpkgs> {} }:
with pkgs;
mkShell {
  inputsFrom = [ (import ./default.nix { inherit pkgs; }).novaboot ];
  buildInputs = [ (perl.withPackages (p: [ p.PodParser ])) ];
}
