#!/usr/bin/env bash
# Makes one short video per task from the guide cards, for WhatsApp:
# each step stays on screen a few seconds and fades into the next.
#
#   docs/guides/video.sh <cards dir> <videos dir>
#
# H.264, 720x1280, 30 fps, yuv420p and +faststart: plays inline on WhatsApp
# on any phone, and stays small (no sound).
set -euo pipefail
CARDS=$1; OUT=$2
STEP=4      # seconds per step
LAST=6      # the last step stays a little longer
FADE=0.5
mkdir -p "$OUT"

for task in $(ls "$CARDS" | sed -E 's/_[0-9]+\.png$//' | sort -u); do
  mapfile -t files < <(ls "$CARDS"/"$task"_*.png | sort -V)
  n=${#files[@]}
  inputs=(); filter=""
  for i in "${!files[@]}"; do
    d=$STEP; [[ $i -eq $((n - 1)) ]] && d=$LAST
    inputs+=(-loop 1 -t "$d" -i "${files[$i]}")
    filter+="[$i:v]scale=720:1280,setsar=1,fps=30,format=yuv420p[v$i];"
  done
  # Chain the steps with cross-fades; each starts where the last one ends.
  last="v0"; offset=0
  for ((i = 1; i < n; i++)); do
    offset=$(echo "$offset + $STEP - $FADE" | bc)
    filter+="[$last][v$i]xfade=transition=fade:duration=$FADE:offset=$offset[x$i];"
    last="x$i"
  done
  filter=${filter%;}
  ffmpeg -loglevel error -y "${inputs[@]}" -filter_complex "$filter" -map "[$last]" \
    -c:v libx264 -preset slow -crf 26 -pix_fmt yuv420p -movflags +faststart "$OUT/$task.mp4"
  echo "$OUT/$task.mp4"
done
