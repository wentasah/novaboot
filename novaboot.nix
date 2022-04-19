{ self
, nixpkgs ? <nixpkgs>
, pkgs ? import nixpkgs { }
, otherPerlPackages ? [ ]
}:
with pkgs;
let
  IO-Stty = perlPackages.buildPerlPackage {
    pname = "IO-Stty";
    version = "0.04";
    src = fetchurl {
      url = "mirror://cpan/authors/id/T/TO/TODDR/IO-Stty-0.04.tar.gz";
      sha256 = "1hjicqy50mgbippn310k4zclr9ksz05yyg81za3q4gb9m3qhk5aw";
    };
  };
  perlEnv = (perl.withPackages (p: [ p.Expect IO-Stty ] ++ otherPerlPackages));
in
{
  novaboot = stdenv.mkDerivation {
    name = "novaboot";
    src = self;
    buildInputs = [ perlEnv rsync ];
    installFlags = "DESTDIR=${placeholder "out"} PREFIX=";
  };
  novaboot-server = stdenv.mkDerivation {
    name = "novaboot-server";
    src = self;
    nativeBuildInputs = [ perl ];
    buildInputs = [ rsync ];
    installFlags = "-C server DESTDIR=${placeholder "out"} PREFIX=";
  };
}
