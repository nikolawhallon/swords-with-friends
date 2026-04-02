#!/usr/bin/env bash

PORT=5001
SESSION="swords-with-friends"
HOST="root@165.232.148.15"
KEY="~/.ssh/id_vacuumbrewstudios"

# 1. export
godot --headless --export-release Linux build/linux/swords-with-friends

# 2. sync
rsync -avz --delete \
  -e "ssh -i $KEY" \
  build/linux/ $HOST:~/swords-with-friends/

# 3. restart remote tmux session
ssh -i $KEY $HOST << EOF
tmux kill-session -t $SESSION 2>/dev/null || true
tmux new -d -s $SESSION 'cd ~/swords-with-friends && ./swords-with-friends --headless --port=$PORT'
EOF

echo "Deployed"
