# Static osm-3s + httpd docker image
# Uses alpine linux docker image as a base and creates a layered image with apache + osm-3s binaries.
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
# To explore image:
# docker run --rm -it --entrypoint /bin/bash osm-3s-static:latest-alpine
#
# To run:
# docker run                            \
# -v <host-osm-data-location>:/mnt/osm  \
# -v <host-log-location>:/mnt/log       \
# -p 8080:80                            \
# osm-3s-static:latest-alpine
# ```
#
# To create and populate a new OSM database:
# TODO: Validate
# ```
# docker run                            \
# -v <host-osm-data-location>:/mnt/osm  \
# -v <host-log-location>:/mnt/log       \
# osm-3s-static:latest-alpine                  \
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
  
  # Base docker image configuration
  # Using Alpine Linux as a base
  basePlatformImages = {
    "x86_64" = {
      imageName = "alpine";
      imageDigest = "sha256:1304f174557314a7ed9eddb4eab12fed12cb0cd9809e4c28f29af86979a3c870";
      sha256 = "1ly61z3bcs5qvqi2xxp3dd3llh61r9gygphl1ib8pxv64ix738mr";
      finalImageName = "alpine";
      finalImageTag = "3.16.2";
    };
    "arm64" = {
      imageName = "alpine";
      imageDigest = "sha256:ed73e2bee79b3428995b16fce4221fc715a849152f364929cdccdc83db5f3d5c";
      sha256 = "1507h3j6xar81cm2zbw7nxcp46z36aflfvsl4979b2kkv07m6q7r";
      finalImageName = "alpine";
      finalImageTag = "3.16.2";
    };
  };
  currentBasePlatformImage = basePlatformImages."${pkgs.stdenv.hostPlatform.linuxArch}";
in
pkgs.dockerTools.buildLayeredImage {
  name = "osm-3s-static";
  tag = "latest-alpine";
  contents = [
    osm3s
    pkgs.apacheHttpd
    pkgs.bash
    pkgs.coreutils
    pkgs.nano
    ./root
  ];
  fromImage = pkgs.dockerTools.pullImage currentBasePlatformImage;
  extraCommands = ''
  # Create launch script
  # Launch osm dispatcher daemon (not necessary for static host)
  echo "${osm3s}/bin/dispatcher --osm-base --db-dir=${osmDataDir}/${osmRelativeDbDir} 1>${logDir}/dispatcher.log 2>&1 &" >> ./start_server.sh

  # Launch apache/httpd
  echo "${pkgs.apacheHttpd}/bin/httpd -DFOREGROUND" >> ./start_server.sh

  # Make script executable
  chmod +x ./start_server.sh
'';
  config = {
    Cmd = ["${pkgs.bash}/bin/bash" "-c" "./start_server.sh"];
  };
}
