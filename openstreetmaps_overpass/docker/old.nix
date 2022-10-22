{ pkgs ? import <nixpkgs> {}
}:

# Using

let
  osm = import ./osm-3s.nix;
in
pkgs.dockerTools.buildLayeredImage {
  name = "osm-3s";
  tag = "latest";
  contents = [
    (pkgs.buildEnv {
      name = "osm-apache";
      paths = [
        pkgs.apacheHttpd
        osm
      ]; 
    })
  ];
  config.Cmd = [ "" ];
}
