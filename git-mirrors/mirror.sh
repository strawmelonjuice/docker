#!/bin/env bash

# A simple script to pull changes from one Git repo and push to another.
# The script reads source and target URLs from a CSV file.

# Use a loop to run the sync process indefinitely

git pull

echo "Git Sync Script Initialized with CSV Input:"
cat repos.csv
echo "\n"

while true; do
    echo "Starting Git synchronization process..."

    # Array to hold background job PIDs
    pids=()

    # Read the CSV file line by line
    while IFS=',' read -r source_repo target_repo; do
        # Skip empty lines and comment lines
        if [[ -z "$source_repo" || "$source_repo" =~ ^# ]]; then
            continue
        fi

        # CSV validation: check for malformed lines
        if [[ -z "$target_repo" ]]; then
            echo "Malformed CSV line: '$source_repo,$target_repo' (missing target repo). Skipping."
            continue
        fi

        (
            echo "---"
            echo "Syncing $source_repo to $target_repo..."

            # Create a temporary directory
            temp_dir=$(mktemp -d -t git_sync_XXXXXX)
            if [ ! -d "$temp_dir" ]; then
                echo "Error: Could not create temporary directory. Exiting."
                exit 1
            fi

            # Go into the temporary directory
            cd "$temp_dir" || { echo "Error: Failed to change directory. Exiting."; exit 1; }

            # Clone the source repository
            echo "Cloning $source_repo..."
            git clone --bare "$source_repo" .
            if [ $? -ne 0 ]; then
                echo "Error: Failed to clone $source_repo. Skipping this pair."
                cd - > /dev/null
                rm -rf "$temp_dir"
                exit 2
            fi

            # Push all branches, and then all tags, separately.
            echo "Pushing all branches to $target_repo..."
            git push --all --force "$target_repo"
            if [ $? -ne 0 ]; then
                echo "Warning: Failed to push branches."
                cd - > /dev/null
                rm -rf "$temp_dir"
                exit 3
            fi

            echo "Pushing all tags to $target_repo..."
            git push --tags --force "$target_repo"
            if [ $? -ne 0 ]; then
                echo "Warning: Failed to push tags."
                cd - > /dev/null
                rm -rf "$temp_dir"
                exit 4
            fi

            # Go back to the original directory and clean up
            cd - > /dev/null
            rm -rf "$temp_dir"
            exit 0
        ) &
        pids+=("$!")
    done < "repos.csv"

    # Wait for all background jobs to finish and track errors
    error_occurred=0
    for pid in "${pids[@]}"; do
        wait "$pid"
        status=$?
        if [ $status -ne 0 ]; then
            error_occurred=1
        fi
    done

    echo "---"
    if [ $error_occurred -eq 1 ]; then
        echo "Not all repository pairs processed. Waiting 2 hours for the next sync cycle..."
    else
        echo "All repository pairs processed. Waiting 2 hours for the next sync cycle..."
    fi
    sleep 7200 # 2 hours
done
