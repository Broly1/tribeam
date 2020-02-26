#!/bin/bash

# fetch.sh: Run fetch-macos.py with safety checks
# by Foxlet <foxlet@furcode.co>

  set +x;
  SCRIPTDIR="$(dirname "$0")";
  cd "$SCRIPTDIR"
  getpython(){
      if [ -x "$(command -v python3)" ]; then
          PYTHONBIN=python3
      elif [ -x "$(command -v python)" ]; then
          PYTHONBIN=python
      elif [ -x "$(command -v python2)" ]; then
          PYTHONBIN=python2
      else
          echo "Please install Python 3 before continuing." >&2
          exit 1;
      fi
  }

  getpython
  $PYTHONBIN fetch-macos.py "$@"

  exit;
