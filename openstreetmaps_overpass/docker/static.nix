# Static osm-3s + httpd docker image
# Contains Apache configuration for hosting an OSM database.
# Database is expected to exist under <TODO>
# No updates are automatically applied to the database.
# Docker image contains only osm-3s + dependencies with httpd as a base.
# To run, `<TODO>`

{ pkgs ? import <nixpkgs> {}
}:

let
  osm = import ../osm-3s.nix;
in
pkgs.dockerTools.buildLayeredImage {
  name = "osm-3s-static";
  tag = "latest";
  contents = [
    osm
  ];
  from = pkgs.dockerTools.pullImage {
    imageName = "httpd";
    imageDigest = if pkgs.stdenv.hostPlatform.isx86 then "sha256:" else "sha256:"
  };
}
