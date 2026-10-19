#!/bin/bash

set -euo pipefail
umask 077

# Assume that this script is stored in the root dir, containing both grant-getter and grant-getter-feed
AUTOMATION_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$AUTOMATION_DIR/grant-getter"
FEED_REPO="$AUTOMATION_DIR/grant-getter-feed"

DATABASE="$PROJECT_DIR/state/production.sqlite3"
LOCK_DIR="$PROJECT_DIR/state/run.lock"

mkdir -p "$PROJECT_DIR/logs" "$PROJECT_DIR/state"

# if LOCK_DIR exists, then it is already a running process
if ! mkdir "$LOCK_DIR" 2>/dev/null; then
    echo "Grant Getter is already running; exiting."
    exit 0
fi

cleanup() {
    rmdir "$LOCK_DIR" 2>/dev/null || true
}
trap cleanup EXIT INT TERM

cd "$PROJECT_DIR"

"$PROJECT_DIR/.venv/bin/python" \
    -m grant_getter \
    --database "$DATABASE" \
    run

# copy new results to the feed repo's feed.xml
cp "$PROJECT_DIR/public/feed.xml" \
   "$FEED_REPO/feed.xml"

cd "$FEED_REPO"

# if nothing to update, don't update
if git diff --quiet -- feed.xml; then
    echo "The RSS feed did not change; nothing to publish."
    exit 0
fi
# commit by adding feed.xml with the updated feed, pushing 

git add feed.xml
git commit \
    -m "Update Grant Getter feed $(date -u '+%Y-%m-%d %H:%M UTC')"
git push origin main

echo "Published the updated RSS feed to GitHub Pages."