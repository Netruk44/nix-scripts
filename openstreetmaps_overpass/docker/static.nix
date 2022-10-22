# Static osm-3s + httpd docker image
# Uses httpd docker image as a base and creates a layered image with osm-3s binaries.
# Does not perform any updates on the attached OSM database.
#
# Expected mount points:
#   - /mnt/osm (Data directory for OSM, configured with `osmDataDir`)
#     - Database is expected to exist under ./db/ (Can be configured with `osmRelativeDbDir`)
#     - Diffs (if used) are expected to exist under ./diffs/
#   - /mnt/log (Logging directory, configured with `logDir`)
#
# TODO: Contains Apache configuration for hosting an OSM database.
#
# No updates are automatically applied to the database.
#   - fetch_osm.sh is not started.
#   - apply_osc_to_db.sh is not started.
#
# To run:
# ```
# docker run osm-3s-static:latest       \
# -v <host-osm-data-location>:/mnt/osm  \
# -v <host-log-location>:/mnt/log
# ```
#
# To create and populate a new OSM database:
# ```
# docker run osm-3s-static:latest       \
# -v <host-osm-data-location>:/mnt/osm  \
# -v <host-log-location>:/mnt/log       \
# /bin/download_clone.sh --db-dir=/mnt/osm/db --source=http://dev.overpass-api.de/api_drolbr/ --meta=no
# ```

{ pkgs ? import <nixpkgs> {}
}:

let
  osm3s = import ../osm-3s.nix {};
  # OSM Settings
  osmDataDir = "/mnt/osm"; # Where in the docker image the root OSM directory is located.
  osmRelativeDbDir = "db"; # Where, relative to osmDataDir, the db directory is located.
  logDir = "/mnt/log"; # Where in the docker image logs should be written to.
  
  # Apache/httpd docker image configuration
  httpdPlatformImages = {
    "x86_64" = {
      imageDigest = "sha256:15515209fb17e06010fa5af6fe15fa0351805cc12acfe82771c7724f06c34ae4";
      sha256 = "1r3zvfas5nb757z26gjmmdkk4hzbrglmj2q9ckhkhdjf77c29qzr";
    };
    "arm64" = {
      imageDigest = "sha256:8b449db91d13460b848b60833cad68bd7f7076358f945bddf14ed4faf470fee4";
      sha256 = "1a0b23pk5lf0fa2z1shggzmcskmj378rafdpfppwg8id6kfwfcgj";
    };
  };
  httpdImageTag = "2.4.54";
  httpdImageName = "httpd";      # e.g. nixos/nix
  httpdFinalImageName = "httpd"; # e.g. nix
  currentHttpdPlatformImage = httpdPlatformImages."${pkgs.stdenv.hostPlatform.linuxArch}";
in
pkgs.dockerTools.buildLayeredImage {
  name = "osm-3s-static";
  tag = "latest";
  contents = [
    osm3s
  ];
  fromImage = pkgs.dockerTools.pullImage {
    imageName = httpdImageName;
    imageDigest = currentHttpdPlatformImage.imageDigest;
    sha256 = currentHttpdPlatformImage.sha256;
    finalImageTag = httpdImageTag;
    finalImageName = httpdFinalImageName;
  };
  extraCommands = ''
  # Create launch script
  # Launch osm dispatcher daemon (not necessary for static host)
  echo "${osm3s}/bin/dispatcher --osm-base --db-dir=${osmDataDir}/${osmRelativeDbDir} 1>${logDir}/dispatcher.log 2>&1 &" >> ./start_server.sh

  # Launch apache/httpd
  echo "/usr/local/bin/httpd-foreground" >> ./start_server.sh
'';
  config = {
    Cmd = ["${pkgs.bash}/bin/bash" "-c" "./start_server.sh"];
  };
}
