#!/bin/bash
declare -r SSH_FILE="$(mktemp -u $HOME/.ssh/XXXXX)"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Decrypt the file containing the private key

openssl aes-256-cbc \
    -K $encrypted_b962e1a718d1_key \
    -iv $encrypted_b962e1a718d1_iv \
    -in ".travis/github_deploy_key_report.enc" \
    -out "$SSH_FILE" -d

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Enable SSH authentication

chmod 600 "$SSH_FILE" \
    && printf "%s\n" \
         "Host github.com" \
         "  IdentityFile $SSH_FILE" \
         "  LogLevel ERROR" >> ~/.ssh/config