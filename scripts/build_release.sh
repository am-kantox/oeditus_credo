#!/usr/bin/env bash
# Build script for OeditusCredo standalone releases

set -e

echo "Building OeditusCredo standalone releases..."
echo ""

# Clean previous builds
echo "Cleaning previous builds..."
rm -f oeditus_credo
rm -f oeditus_credo-*.ez

# Get dependencies
echo "Getting dependencies..."
mix deps.get

# Compile
echo "Compiling..."
MIX_ENV=prod mix compile

# Build escript
echo "Building escript..."
MIX_ENV=prod mix escript.build

# Build archive
echo "Building hex archive..."
MIX_ENV=prod mix archive.build

echo ""
echo "Build complete!"
echo ""
echo "Artifacts created:"
echo "  - oeditus_credo (escript executable)"
ls -lh oeditus_credo-*.ez 2>/dev/null | awk '{print "  - " $9 " (hex archive)"}'
echo ""
echo "To test:"
echo "  ./oeditus_credo --help"
echo "  mix archive.install ./oeditus_credo-*.ez"
echo ""
