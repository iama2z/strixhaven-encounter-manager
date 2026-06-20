#!/bin/bash
set -e

echo "=========================================================="
echo "Initializing Multica Agentic Workflow..."
echo "=========================================================="

echo "Installing tmux for detached daemon runs..."
sudo apt-get update && sudo apt-get install -y tmux screen

echo "Installing Multica CLI..."
# Attempt to install Multica CLI using a standard curl script, assuming one exists.
# Replace with the actual URL provided by your platform.
curl -fsSL https://raw.githubusercontent.com/multica-io/multica/main/install.sh | bash || {
  echo "Warning: Automated install script failed. Please install the CLI manually."
}

echo "=========================================================="
echo "Codespace Environment Initialized!"
echo ""
echo "Next Steps to activate the Agent Runtime:"
echo "1. Run 'multica login' to authenticate with the platform."
echo "2. Start the daemon in a detached tmux session so it survives disconnections:"
echo "   tmux new-session -d -s multica 'multica daemon start'"
echo "   (Attach using 'tmux attach -t multica')"
echo "=========================================================="
