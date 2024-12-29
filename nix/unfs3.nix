{ pkgs ? import <nixpkgs> { } }:
with pkgs;
stdenv.mkDerivation rec {
  pname = "unfs3";
  version = "0.10.0-novaboot";
  src = fetchFromGitHub {
    owner = "wentasah";
    repo = "unfs3";
    # ref = "refs/heads/novaboot";
    rev = "6637b9a371575fde613db9081b25610f30f4b564";
    sha256 = "1sy7rlkpbqbilvbi8878vvbaql058iy0ib3sakcv15asmky4385a";
    # date = "2024-12-29T11:44:08+01:00";
  };

  nativeBuildInputs = [ autoconf automake bison flex pkg-config ];
  buildInputs = [ libtirpc ];

  preConfigure = "./bootstrap";
}
