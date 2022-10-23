# Static osm-3s + httpd docker image
# Uses httpd docker image as a base and creates a layered image with osm-3s binaries.
# Does not perform any updates on the attached OSM database.
#
# Expected mount points:
#   - /mnt/osm (Data directory for OSM)
#     - Database is expected to exist under ./db/
#     - Diffs (if used) are expected to exist under ./diffs/
#   - /mnt/log (Logging directory, configured with `logDir`)
#
# Contains Apache configuration for hosting an OSM server under ./image_root.
#
# No updates are automatically applied to the database.
#   - fetch_osm.sh is not started.
#   - apply_osc_to_db.sh is not started.
#
# To run:
# ```
# docker [run/create]                   \
# -v <host-osm-data-location>:/mnt/osm  \
# -v <host-log-location>:/mnt/log       \
# -p 8080:80                            \
# osm-3s-static:latest
# ```
#
# To create and populate a new OSM database:
# NOTE: As of October 2022, this requires ~180 GB, and is always increasing.
#       You can get a rough estimate of space needed by looking at the size of planet.osm: https://planet.openstreetmap.org/
#       As of October 2022, the planet.osm file is 120 GB. Multiply by 1.5 for *rough* estimate of database size.
# ```
# docker run                            \
# -v <host-osm-data-location>:/mnt/osm  \
# osm-3s-static:latest                  \
# /bin/download_clone.sh --db-dir=/mnt/osm/db --source=http://dev.overpass-api.de/api_drolbr/ --meta=no
# ```

{ pkgs ? import <nixpkgs> { pkgs = pkgs; }
}:

let
  osm3s = import ../osm-3s.nix {};
  # OSM Settings
  osmDataDir = "/mnt/osm"; # Where in the docker image the root OSM directory is located.
  osmRelativeDbDir = "db"; # Where, relative to osmDataDir, the db directory is located.
  logDir = "/mnt/log"; # Where in the docker image logs should be written to.

  startupScript = pkgs.writeTextFile {
    name = "start_server.sh";
    executable = true;
    text = ''
    echo "Starting OSM Dispatcher..."
    rm ${osmDataDir}/${osmRelativeDbDir}/osm3s_v* || true
    ${osm3s}/bin/dispatcher --osm-base --db-dir=${osmDataDir}/${osmRelativeDbDir} 1>${logDir}/dispatcher.log 2>&1 &

    echo "Starting httpd..."
    /usr/local/bin/httpd-foreground
    '';
  };
  
  # Base docker image configuration
  # Using apache/httpd as a base, as it includes apache utility binaries and configuration already setup.
  basePlatformImages = {
    "x86_64" = {
      imageName = "httpd";
      imageDigest = "sha256:15515209fb17e06010fa5af6fe15fa0351805cc12acfe82771c7724f06c34ae4";
      sha256 = "1r3zvfas5nb757z26gjmmdkk4hzbrglmj2q9ckhkhdjf77c29qzr";
      finalImageName = "httpd";
      finalImageTag = "2.4.54";
    };
    "arm64" = {
      imageName = "httpd";
      imageDigest = "sha256:8b449db91d13460b848b60833cad68bd7f7076358f945bddf14ed4faf470fee4";
      sha256 = "1a0b23pk5lf0fa2z1shggzmcskmj378rafdpfppwg8id6kfwfcgj";
      finalImageName = "httpd";
      finalImageTag = "2.4.54";
    };
  };
  currentBasePlatformImage = basePlatformImages."${pkgs.stdenv.hostPlatform.linuxArch}";
in
pkgs.dockerTools.buildLayeredImage {
  name = "osm-3s-static";
  tag = "latest";
  contents = [
    osm3s
    pkgs.nano     # Useful for debugging, not necessary
    #pkgs.wget     # Required for download_clone.sh and fetch_osm.sh
    ./image_root  # Apache host configuration
  ];
  fromImage = pkgs.dockerTools.pullImage currentBasePlatformImage;
  config = {
    Cmd = ["${pkgs.bash}/bin/bash" "-c" startupScript];
  };
}
