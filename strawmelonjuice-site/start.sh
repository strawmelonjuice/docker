#!/bin/bash

(
  while true; do
    sleep 300
    echo "Checking for site updates..."
    usr/bin/mise run site-generate
  done
) &

# This replaces the earlier docker entrypoint script functionality which used to run Cynthia Mini in dynamic (hosted) mode.
#
# However, this script too, is unused, as seen by the addition of the systemd service and timer files
# which now handle site generation every 3 minutes.