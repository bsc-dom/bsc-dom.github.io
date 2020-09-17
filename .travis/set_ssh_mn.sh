#!/bin/bash
declare -r SSH_FILE="$(mktemp -u $HOME/.ssh/XXXXX)"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Decrypt the file containing the private key
openssl aes-256-cbc \
	-K $encrypted_12a78a482e9b_key -iv $encrypted_12a78a482e9b_iv \
	-in .travis/marenostrum_deploy_key.enc \
	-out "$SSH_FILE" -d

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Enable SSH authentication
chmod 600 "$SSH_FILE" \
    && printf "%s\n" \
         "Host dt01.bsc.es" \
         "  IdentityFile $SSH_FILE" \
         "  LogLevel ERROR" >> ~/.ssh/config \
    && printf "%s\n" \
         "Host mn1.bsc.es" \
         "  IdentityFile $SSH_FILE" \
         "  LogLevel ERROR" >> ~/.ssh/config
         
chmod 600 "$SSH_FILE" \
    && printf "%s\n" \
         "Host *" \
         "  StrictHostKeyChecking no" \
         "  UserKnownHostsFile=/dev/null" >> ~/.ssh/config