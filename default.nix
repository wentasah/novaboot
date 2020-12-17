{
  nixpkgs ? <nixpkgs>,
  pkgs ? import nixpkgs {}
}:
with pkgs;
let
  IO-Stty = buildPerlPackage {
    pname = "IO-Stty";
    version = "0.04";
    src = fetchurl {
      url = "mirror://cpan/authors/id/T/TO/TODDR/IO-Stty-0.04.tar.gz";
      sha256 = "1hjicqy50mgbippn310k4zclr9ksz05yyg81za3q4gb9m3qhk5aw";
    };
  };
  perlEnv = (perl.withPackages (p: [ p.Expect IO-Stty ]));
in
{
  novaboot = stdenv.mkDerivation {
    name = "novaboot";
    src = builtins.fetchGit { url = ./.; };
    buildInputs = [ perlEnv rsync ];
    installPhase = ''
    make install DESTDIR=$out PREFIX=
  '';
  };
  novaboot-server = stdenv.mkDerivation {
    name = "novaboot-server";
    src = builtins.fetchGit { url = ./.; };
    nativeBuildInputs = [ perl ];
    buildInputs = [ rsync ];
    installPhase = ''
    make -C server install DESTDIR=$out PREFIX=
  '';
  };
}
