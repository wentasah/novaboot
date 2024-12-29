{ pkgs ? import <nixpkgs> { } }:
with pkgs;
stdenv.mkDerivation rec {
  pname = "unfs3";
  version = "0.10.0-novaboot";
  src = fetchFromGitHub {
    owner = "wentasah";
    repo = "unfs3";
    # ref = "refs/heads/novaboot";
    rev = "a7c674844a0844b1e3bbabae8c37e398d8a0b5c8";
    sha256 = "0xmcp7kpf65x379xvna5fvqr91f8wny4dm2w0zlw1v7rmbln98ij";
    # date = "2024-12-29T15:16:46+01:00";
  };

  nativeBuildInputs = [ autoconf automake bison flex pkg-config ];
  buildInputs = [ libtirpc ];

  preConfigure = "./bootstrap";
}
