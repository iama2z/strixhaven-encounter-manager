# Multica Agentic Workflow in GitHub Codespaces

This repository is configured to run smoothly as a GitHub Codespace, providing an isolated, cloud-based environment for both you and your Multica agents.

## Getting Started

1. **Spin up the Codespace:**
   Click the green **Code** button on the repository page, switch to the **Codespaces** tab, and click **Create codespace on main**.
   GitHub will build the container based on the `.devcontainer/devcontainer.json` file. This installs all required tools (Python, Node.js, Git, Docker, etc.).

2. **Wait for Post-Create Initialization:**
   Upon creation, the `.devcontainer/post-create.sh` script runs automatically. It installs `tmux` and attempts to install the `multica` CLI.
   Wait for this script to finish and confirm success in the terminal output.

3. **Authenticate:**
   Open a terminal in VS Code inside the Codespace and run:
   ```bash
   multica login
   ```
   Follow the prompts to log in to your Multica workspace.

4. **Start the Multica Daemon (Persisted):**
   To ensure agents can run in the background even if your browser connection drops, start the daemon in a detached `tmux` session:
   ```bash
   tmux new-session -d -s multica 'multica daemon start'
   ```
   *Note: You can view the daemon logs by attaching to the session: `tmux attach -t multica`. To detach again without stopping it, press `Ctrl+B` then `D`.*

## Assigning Agents to the Cloud Runtime

With the daemon running, your Codespace acts as a **local runtime** for the assigned Multica project. Any agents assigned to tasks in this project will now execute within this Codespace.

- **Check Runtime Status:** Verify the daemon is online in your Multica platform dashboard or via `multica runtime list`.
- **Collaborate:** Agents will check out branches, read code, write files, and run commands inside this very container! You can see their changes stream into your editor in real time.

## Troubleshooting

- **CLI not installed:** If `multica` is not recognized, the automated install may have failed. Refer to the official Multica docs to install the CLI.
- **Daemon stopped:** If the Codespace suspends or is restarted, the `tmux` session is lost. You will need to start the daemon again with `tmux new-session -d -s multica 'multica daemon start'`.
