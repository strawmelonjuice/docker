#!/bin/bash

echo "Fetching site files..."
rm -rf ./site
git clone https://github.com/strawmelonjuice/strawmelonjuice-site ./site

if [ ! -f "./cynthiaweb-mini" ]; then
  echo "cynthiaweb-mini not found, installing..."
  curl -L -o cynthiaweb-mini-weekly.tgz https://github.com/strawmelonjuice/Mini-strawmelonjuice.com/releases/download/weekly-build/cynthiaweb-mini-weekly.tgz
  mkdir -p build
  tar -xzf cynthiaweb-mini-weekly.tgz -C build
  bun build --compile build/dist/cynthia_websites_mini_server.js --outfile ./cynthiaweb-mini
  chmod +x ./cynthiaweb-mini
  rm cynthiaweb-mini-weekly.tgz
  rm -rf build
  echo "cynthiaweb-mini installed successfully."
else
  echo "✓ cynthiaweb-mini is already installed."
fi

# Pulls changes every 5 minutes (300 seconds)
(
  while true; do
    sleep 300
    echo "Checking for site updates..."
    git -C ./site pull
  done
) &

# While loop restarts cynthiaweb-mini up to 3 times
FAIL_COUNT=0
MAX_RETRIES=3

while [ $FAIL_COUNT -lt $MAX_RETRIES ]; do
  echo "Starting Cynthia engine (Attempt $((FAIL_COUNT + 1)))..."

  cd ./site && ../cynthiaweb-mini dynamic

  EXIT_CODE=$?
  FAIL_COUNT=$((FAIL_COUNT + 1))

  echo "Process exited with code $EXIT_CODE. Failure $FAIL_COUNT/$MAX_RETRIES."

  if [ $FAIL_COUNT -lt $MAX_RETRIES ]; then
    echo "Restarting in 5 seconds..."
    sleep 5
  fi
done

echo "Cynthia engine failed $MAX_RETRIES times. Shutting down."
exit 1
