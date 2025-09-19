#!/bin/bash

# Parse runner labels from images.json using host jq
if [ -f "images.json" ]; then
    export RUNNER_LABELS=$(jq -r '.runner_labels | map("\(.label):\(.image)") | join(",")' images.json)
    echo "Parsed runner labels: $RUNNER_LABELS"
else
    echo "Warning: images.json not found, using default labels"
    export RUNNER_LABELS="ubuntu-latest:docker://ubuntu:latest"
fi

# Start docker-compose
docker-compose up -d
