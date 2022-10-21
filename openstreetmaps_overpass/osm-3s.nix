{ pkgs ? import <nixpkgs> {}
}:

pkgs.stdenv.mkDerivation rec {
  pname = "osm-3s";
  version = "0.7.59";
  buildInputs = [pkgs.expat pkgs.zlib];
  enableParallelBuilding = true;
  src = pkgs.fetchurl {
    url = "http://dev.overpass-api.de/releases/osm-3s_v${version}.tar.gz";
    sha256 = "02jk3rqhfwdhfnwxjwzr1fghr3hf998a3mhhk4gil3afkmcxd40l";
  };
  CXXFLAGS = "-O2";
  meta = {
    description = "OpenStreetMaps Overpass API Server";
    longDescription = ''
      The OSM Overpass service provides an API to serve up
      selected parts of the complete Open Street Map dataset.
    '';
    homepage = "http://overpass-api.de/";
    license = pkgs.lib.licenses.agpl3Only;
  };
}
