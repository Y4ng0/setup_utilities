#!/bin/bash

set -e  # Exit on error

# === STEP 1: Fix home dir on login and suppress MOTD ===
cd ~

echo "Adding 'cd ~' to .bashrc if not already present..."
if ! grep -Fxq "cd ~" ~/.bashrc; then
    echo "cd ~" >> ~/.bashrc
    echo "✓ Added 'cd ~' to ~/.bashrc"
else
    echo "⏩ 'cd ~' already present in ~/.bashrc"
fi

echo "Creating ~/.hushlogin to suppress login messages..."
touch ~/.hushlogin
echo "✓ Created ~/.hushlogin"

# === STEP 2: System update and upgrade ===
echo "Running apt update and upgrade..."
sudo apt update
sudo apt upgrade -y
echo "✓ System updated."

# === STEP 3: Ensure git is installed ===
if ! command -v git &> /dev/null; then
    echo "Git not found. Installing..."
    sudo apt install -y git
    echo "✓ Git installed."
else
    echo "⏩ Git already installed."
fi

# === STEP 4: Prompt for Git credentials ===
echo ""
read -p "Enter your Git server URL (e.g., github.com or git.mycompany.com): " GIT_HOST
read -p "Enter your Git username: " GIT_USER
read -s -p "Enter your Git personal access token: " GIT_TOKEN
echo ""

# === STEP 5: Store credentials for Git HTTPS usage ===
CRED_HELPER=$(git config --global credential.helper || echo "")
if [ "$CRED_HELPER" != "store" ]; then
    git config --global credential.helper store
    echo "✓ Git credential.helper set to 'store'"
fi

# Prime credentials for HTTPS access (optional, but helpful)
echo "https://${GIT_USER}:${GIT_TOKEN}@${GIT_HOST}" > ~/.git-credentials
git config --global user.name "$GIT_USER"
git config --global user.email "${GIT_USER}@${GIT_HOST}"

echo "✓ Git credentials stored for ${GIT_HOST}"
echo "Done."
