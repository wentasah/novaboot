{ pkgs ? import <nixpkgs> { } }:
with pkgs;
stdenv.mkDerivation rec {
  pname = "unfs3";
  version = "0.9.22-novaboot";
  src = fetchFromGitHub {
    owner = "skoudmar";
    repo = "unfs3";
    #rev = "unfs3-${version}";
    rev = "eb5ccdfe723fa37fd80f37ef079d97cbc6b72d44";
    sha256 = "sha256-n9pI1/6yoYfY9fo/EXMhqJhMn77oR5PvtZOdqD6/Erk=";
  };

  nativeBuildInputs = [ autoconf automake bison flex pkg-config ];
  buildInputs = [ libtirpc ];

  preConfigure = "./bootstrap";
}
