#!/bin/sh
# Runs the swift-testing suite. With Command Line Tools only (no Xcode), the Testing framework lives
# outside the default search path and its Foundation overlay ships without a module, hence the flags.
set -e
cd "$(dirname "$0")/.."

# Budget guard (docs/HLD.md §9): nothing in the app may tick on a repeating timer or a sleep loop.
if grep -rnE 'repeats: *true|Task\.sleep|Timer\.publish' Sources; then
  echo "error: repeating timers / sleep loops are banned; derive live values in views or use OneShotScheduler" >&2
  exit 1
fi
F=/Library/Developer/CommandLineTools/Library/Developer/Frameworks
L=/Library/Developer/CommandLineTools/Library/Developer/usr/lib
if [ -d "$F/Testing.framework" ] && ! xcode-select -p | grep -q Xcode.app; then
  exec swift test -Xswiftc -F"$F" -Xswiftc -Xfrontend -Xswiftc -disable-cross-import-overlays \
    -Xlinker -F"$F" -Xlinker -rpath -Xlinker "$F" -Xlinker -rpath -Xlinker "$L" "$@"
fi
exec swift test "$@"
