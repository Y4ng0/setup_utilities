#!/bin/bash

set -e  # Exit on error

# === STEP 0: Ensure script is run in interactive shell ===
if [[ ! -t 0 || ! -t 1 ]]; then
  echo "❌ This script must be run in an interactive shell (not piped via curl | bash)."
  echo "👉 Clone the repo or run: bash <(curl -fsSL https://...)"
  exit 1
fi

cd ~

echo "🔧 Adding 'cd ~' to .bashrc if not already present..."
if ! grep -Fxq "cd ~" ~/.bashrc; then
    echo "cd ~" >> ~/.bashrc
    echo "✓ Added 'cd ~' to ~/.bashrc"
else
    echo "⏩ 'cd ~' already present."
fi

echo "📵 Creating ~/.hushlogin to suppress login messages..."
touch ~/.hushlogin
echo "✓ Created ~/.hushlogin"

echo "📦 Running apt update and upgrade..."
sudo apt update
sudo apt upgrade -y
echo "✓ System updated."

echo "🔍 Checking for Git..."
if ! command -v git &> /dev/null; then
    echo "Git not found. Installing..."
    sudo apt install -y git
    echo "✓ Git installed."
else
    echo "⏩ Git already installed."
fi

echo ""
echo "🔐 Let's configure your Git credentials (Personal Access Token)"
echo "💡 GitHub: https://github.com/settings/tokens"
echo "💡 GitLab: https://gitlab.com/-/profile/personal_access_tokens"
echo "✅ Recommended scopes:"
echo "   - GitHub: 'repo', 'read:org'"
echo "   - GitLab: 'api', 'read_repository', 'write_repository'"
echo ""

read -rp "Enter your Git server (e.g. github.com or gitlab.com): " GIT_HOST
read -rp "Enter your Git username: " GIT_USER
read -rsp "Enter your Git Personal Access Token: " GIT_TOKEN
echo ""

# === Token verification ===
verify_token() {
  echo "🔍 Verifying token with $1..."

  if [[ "$1" == *"github.com"* ]]; then
    RESPONSE=$(curl -s -i -H "Authorization: token $GIT_TOKEN" https://api.github.com/user)
    if echo "$RESPONSE" | grep -q "200 OK"; then
      SCOPES=$(echo "$RESPONSE" | grep "X-OAuth-Scopes")
      echo "✅ GitHub token is valid."
      echo "🔎 Scopes: $SCOPES"
      if [[ "$SCOPES" != *"repo"* ]]; then
        echo "⚠️  'repo' scope missing — may not be able to access private repos."
      fi
    else
      echo "❌ Invalid GitHub token. Exiting."
      exit 1
    fi

  elif [[ "$1" == *"gitlab.com"* ]] || [[ "$1" == *"."* ]]; then
    RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" --header "PRIVATE-TOKEN: $GIT_TOKEN" "https://$1/api/v4/user")
    if [[ "$RESPONSE" == "200" ]]; then
      echo "✅ GitLab token is valid."
      echo "⚠️  GitLab does not expose scopes. Make sure it includes 'api' or repo access."
    else
      echo "❌ Invalid GitLab token or host unreachable. Exiting."
      exit 1
    fi
  else
    echo "❓ Unknown Git host type. Cannot verify."
  fi
}

verify_token "$GIT_HOST"

# Configure Git
CRED_HELPER=$(git config --global credential.helper || echo "")
if [ "$CRED_HELPER" != "store" ]; then
    git config --global credential.helper store
    echo "✓ Set Git credential.helper to 'store'"
fi

# Store credential in .git-credentials
echo "https://${GIT_USER}:${GIT_TOKEN}@${GIT_HOST}" > ~/.git-credentials

# Set global user info (optional, override if needed later)
git config --global user.name "$GIT_USER"
git config --global user.email "${GIT_USER}@${GIT_HOST}"

echo ""
echo "✅ Git is configured with your credentials for ${GIT_HOST}"
echo "You can now clone and push without entering your credentials every time."
echo ""
echo "🎉 Setup complete!"
