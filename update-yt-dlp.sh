#!/bin/sh
set -e
cd "$(dirname "$0")"
git submodule update --remote vendor/yt-dlp
git -C vendor/yt-dlp describe --tags 2>/dev/null || git -C vendor/yt-dlp rev-parse --short HEAD
echo "yt-dlp updated. Rebuild .deb with: make package"
