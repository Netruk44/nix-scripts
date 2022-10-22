# Static osm-3s + httpd docker image
# Contains Apache configuration for hosting an OSM database.
# Database is expected to exist under <TODO>
# No updates are automatically applied to the database.
# Docker image contains only osm-3s + dependencies with httpd as a base.
# To run, `<TODO>`

{ pkgs ? import <nixpkgs> {}
}:

let
  osm = import ../osm-3s.nix {};
  httpdPlatformImages = {
    "x86_64" = {
      imageDigest = "sha256:15515209fb17e06010fa5af6fe15fa0351805cc12acfe82771c7724f06c34ae4";
      sha256 = "";
    };
    "arm64" = {
      imageDigest = "sha256:8b449db91d13460b848b60833cad68bd7f7076358f945bddf14ed4faf470fee4";
      sha256 = "";
    };
  };
  httpdImageTag = "2.4.54";
  httpdImageName = "httpd";
  currentHttpdPlatformImage = httpdPlatformImages."${pkgs.stdenv.hostPlatform.linuxArch}";
in
pkgs.dockerTools.buildLayeredImage {
  name = "osm-3s-static";
  tag = "latest";
  contents = [
    osm
  ];
  fromImage = pkgs.dockerTools.pullImage {
    imageName = "httpd";
    imageDigest = currentHttpdPlatformImage.imageDigest;
    sha256 = currentHttpdPlatformImage.sha256;
    finalImageTag = httpdImageTag;
    finalImageName = httpdImageName;
  };
}
