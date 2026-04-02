#!/usr/bin/env bash
set -e

NAME="swords-with-friends"
PORT=5001
HOST="root@165.232.148.15"
KEY="~/.ssh/id_vacuumbrewstudios"

# 1. export
godot --headless --export-release "Linux" build/linux/$NAME

# 2. sync
rsync -av --delete --whole-file \
  -e "ssh -i $KEY" \
  build/linux/ $HOST:~/$NAME/

# 3. restart remote tmux session
ssh -i $KEY $HOST << EOF
tmux kill-session -t $NAME 2>/dev/null || true
tmux new -d -s $NAME 'cd ~/$NAME && ./$NAME --headless --port=$PORT'
EOF

echo "Deployed $NAME on port $PORT"
