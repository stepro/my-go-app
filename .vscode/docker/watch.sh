#!/bin/sh

# Parse arguments
SOURCE="${1:-/.src}"
TARGET="${2:-$(pwd)}"

# Change to source directory
cd "$SOURCE"

# Create watch directory
mkdir -p /.watch

# Ignore files in .dockerignore
FIND_OPTS=-ignore_readdir_race
if [ -e .dockerignore ]; then
  echo -n > /.watch/find_opts
  cat .dockerignore | sed -e 's/\r//' -e '$s/$/\n/' | while read line; do
    if [ -n "$line" ]; then
      COMMENT=$(echo $line | grep ^#)
      if [ -z "$COMMENT" ]; then
        echo -path ./$line -prune -o >> /.watch/find_opts
      fi
    fi
  done
  FIND_OPTS="$FIND_OPTS $(cat /.watch/find_opts)"
  rm /.watch/find_opts
fi
FIND_ALL_OPTS="$FIND_OPTS -print"
FIND_NEWER_OPTS="$FIND_OPTS -newer /.watch/last -print"

# Initialize state
find $FIND_ALL_OPTS | sed 's/^\.\///' > /.watch/baseline
touch -t $(date +%Y%m%d%H%M.%S) /.watch/last

# Start watch loop
while true; do
  # Detect deleted and added files
  find $FIND_ALL_OPTS | sed 's/^\.\///' > /.watch/current
  diff /.watch/baseline /.watch/current > /.watch/diff
  cat /.watch/diff | grep ^\< | cut -c2- | while read deleted; do
    rm -rf "$TARGET/$deleted"
  done
  cat /.watch/diff | grep ^\> | cut -c2- | while read added; do
    if [ -d "$added" ]; then
      mkdir -p "$TARGET/$added"
    else
      diff "$TARGET/$added" "$added" > /dev/null 2>&1
      if [ $? != 0 ]; then
        DIR=$(dirname "$added")
        mkdir -p "$TARGET/$DIR"
        cp "$added" "$TARGET/$added"
      fi
    fi
  done
  mv /.watch/current /.watch/baseline

  # Detect updated files
  touch -t $(date +%Y%m%d%H%M.%S) /.watch/now
  sleep 1 # MUST be here due to second precision on Mac
  find $FIND_NEWER_OPTS | sed 's/^\.\///' | while read newer; do
    if [ -f "$newer" ]; then
      diff "$TARGET/$newer" "$newer" > /dev/null 2>&1
      if [ $? != 0 ]; then
        DIR=$(dirname "$newer")
        mkdir -p "$TARGET/$DIR"
        cp "$newer" "$TARGET/$newer"
      fi
    fi
  done
  mv /.watch/now /.watch/last
done
