#!/bin/bash

set -e  # Exit on error

# Make sure we're in the user's home directory
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

echo "Done. Restart your shell to apply changes."
