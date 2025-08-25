#!/usr/bin/env bash

# Script for installing NixOS
# ---------------------------
#
# @author: Eloy García Almadén
# @email: eloy.garcia.pca@gmail.com
# GitHub: https://github.com/egara/nixos-config
# Inspired by Martin Wimpress: https://github.com/wimpysworld/nix-config
# ---------------------------

set -euo pipefail

TARGET_HOST="${1:-}"
TARGET_USER="${2:-jonathanrg}"

# Executing additional scripts
echo "Executing additional scripts for host $TARGET_HOST..."
pushd "$HOME/Zero/nixos-config/hosts/kratos/scripts"
for script in *.sh; do
  bash "$script"
done

pushd "$HOME/Zero/nixos-config"

# Creating mounting point for BTRFS full volume
sudo mkdir -p /mnt/mnt/defvol

sudo nixos-install --no-root-password --flake ".#$TARGET_HOST"

# Rsync nix-config to the target install and set the remote origin to SSH.
rsync -a --delete "$HOME/Zero/" "/mnt/home/$TARGET_USER/Zero/"
pushd "/mnt/home/$TARGET_USER/Zero/nixos-config"
git remote set-url origin git@github.com:jonathanrg/nixos-config.git
popd
