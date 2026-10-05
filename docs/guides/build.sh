#!/usr/bin/env bash
# Rebuilds the collector guide from the app as it is now:
#   1. the guide test drives the real app and saves each step's screen;
#   2. mark.py circles where to tap and adds the captions (cards);
#   3. video.sh joins each task's cards into a short video.
# Output: docs/guides/collector/{cards,videos}. Uses demo data only.
#
#   docs/guides/build.sh
set -euo pipefail
cd "$(dirname "$0")/../.."
GUIDES=docs/guides/collector
export PATH="$HOME/flutter/bin:$PATH"

(cd mobile && flutter test test/guide/guide_screens_test.dart --dart-define=GUIDE=true --update-goldens)
rm -rf "$GUIDES/cards" "$GUIDES/videos"
python3 docs/guides/mark.py mobile/test/guide/shots "$GUIDES/cards" >/dev/null
bash docs/guides/video.sh "$GUIDES/cards" "$GUIDES/videos"
echo "Cards: $GUIDES/cards   Videos: $GUIDES/videos"
