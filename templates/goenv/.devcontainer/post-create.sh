#!/usr/bin/env sh

# Fix ownership of the home directory
sudo chown -R vscode:vscode /home/vscode/
git config --global core.pager "less"
git config --global --unset interactive.diffFilter 2>/dev/null || true

echo "Updating shell configurations..."

if ! grep -qF 'direnv hook bash' /etc/bash.bashrc; then
    echo 'eval "$(direnv hook bash)"' | sudo tee -a /etc/bash.bashrc > /dev/null
fi

if grep -qF 'direnv hook zsh' /etc/zsh/zshrc; then
    echo 'eval "$(direnv hook zsh)"' | sudo tee -a /etc/zsh/zshrc > /dev/null
fi

direnv allow /workspaces/.envrc
