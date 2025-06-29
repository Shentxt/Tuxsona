#!/bin/bash

# Configuration
RESOLUTION="1920x1080"
DISPLAY_NUM=":5"

echo "🎬 Launching temporary X11 environment (Xephyr) on $DISPLAY_NUM..."

# Launch Xephyr in background
Xephyr $DISPLAY_NUM -screen $RESOLUTION -br -ac &
XEPHYR_PID=$!

# Ensure Xephyr has started
sleep 1

# Export DISPLAY to run plymouth inside Xephyr
export DISPLAY=$DISPLAY_NUM

echo "🧪 Launching Plymouth inside Xephyr..."

# Start plymouthd with debug
sudo plymouthd --debug

# Show splash
sudo plymouth --show-splash

echo "🖼️ Animation launched inside Xephyr window"
echo "🔁 Loop: press Ctrl+C to exit..."

# Capture Ctrl+C to cleanly close
trap "echo '⛔ Closing preview session...'; sudo plymouth --quit; kill $XEPHYR_PID; exit" SIGINT

# Wait indefinitely
while true; do
  sleep 1
done
