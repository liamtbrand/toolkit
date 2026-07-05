#!/usr/bin/env bash
set -euo pipefail

# Force correct permissions in .ssh directory

mkdir -p ~/.ssh
chown -R $USER:$(id -gn) ~/.ssh
chmod 700 ~/.ssh

# Set 600 for private keys
[ -f "~/.ssh/id_rsa" ] && chmod 600 "~/.ssh/id_rsa"
[ -f "~/.ssh/id_ed25519" ] && chmod 600 "~/.ssh/id_ed25519"

# Set 644 for public keys
[ -f "~/.ssh/id_rsa.pub" ] && chmod 644 "~/.ssh/id_rsa.pub"
[ -f "~/.ssh/id_ed25519.pub" ] && chmod 644 "~/.ssh/id_ed25519.pub"

[ -f "~/.ssh/authorized_keys" ] && chmod 600 "~/.ssh/authorized_keys"
[ -f "~/.ssh/known_hosts" ] && chmod 644 "~/.ssh/known_hosts"
[ -f "~/.ssh/config" ] && chmod 600 "~/.ssh/config"

echo "Permissions fixed."
