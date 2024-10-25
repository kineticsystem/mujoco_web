#!/bin/bash
set -e

# Function: apply_patches
# Description: Applies all .patch files in the specified directory in sorted order.
# Usage: apply_patches "/path/to/patches_dir"
apply_patches() {
    local PATCHES_DIR="$1"

    # Check if PATCHES_DIR is provided
    if [[ -z "$PATCHES_DIR" ]]; then
        echo "Error: No patches directory provided."
        echo "Usage: apply_patches \"/path/to/patches_dir\""
        return 1
    fi

    # Check if PATCHES_DIR exists and is a directory
    if [[ ! -d "$PATCHES_DIR" ]]; then
        echo "Error: Directory '$PATCHES_DIR' does not exist."
        return 1
    fi

    # Find all .patch files in PATCHES_DIR, sorted alphanumerically
    mapfile -t PATCH_FILES < <(find "$PATCHES_DIR" -maxdepth 1 -type f -name "*.patch" | sort)

    # Check if any patch files were found
    if [[ ${#PATCH_FILES[@]} -eq 0 ]]; then
        echo "No .patch files found in '$PATCHES_DIR'."
        return 0
    fi

    echo "Found ${#PATCH_FILES[@]} patch file(s) in '$PATCHES_DIR'."

    # Iterate over each patch file
    for patch_file in "${PATCH_FILES[@]}"; do
        # Get the base name of the patch file for display
        local patch_name
        patch_name=$(basename "$patch_file")

        echo "Applying patch: $patch_name"

        # Apply the patch
        # Flags:
        # -N : Ignore patches that seem to be reversed or already applied
        # -b : Make a backup before applying the patch
        # -p1 : Strip the first level of directories from file paths in the patch
        # -i : Specify the patch file
        patch -Nbp1 -i "$patch_file"

        # Capture the exit status of the patch command
        local patch_status=$?

        if [[ $patch_status -eq 0 ]]; then
            echo "Successfully applied: $patch_name"
        elif [[ $patch_status -eq 1 ]]; then
            echo "Warning: Failed to apply patch '$patch_name'. It may already be applied or have conflicts."
            # Optionally, you can choose to exit or continue
            # Uncomment the next line to exit on failure
            # return 1
        else
            echo "Error: An unexpected error occurred while applying '$patch_name'. Exit status: $patch_status"
            # Optionally, exit on unexpected errors
            # Uncomment the next line to exit on unexpected errors
            # return $patch_status
        fi

        echo "----------------------------------------"
    done

    # Clean up any backup files (*.orig) generated by the patch command
    echo "Cleaning up backup files (*.orig)..."
    find . -type f -name "*.orig" -exec rm -f {} +

    echo "All patches have been processed."
    return 0
}

function install-all {
    # Export environment variables.

    export THREADS=16
    export CURRENT_DIR=$(pwd)

    export DEPS_DIR=$CURRENT_DIR/deps
    if [ ! -d "$DEPS_DIR" ]; then
        mkdir -p "$DEPS_DIR"
    fi

    export SRC_DIR=$DEPS_DIR/src
    if [ ! -d "$SRC_DIR" ]; then
        mkdir -p "$SRC_DIR"
    fi

    export DST_DIR=$DEPS_DIR/dst
    if [ ! -d "$DST_DIR" ]; then
        mkdir -p "$DST_DIR"
    fi

    export BUILD_DIR=$DEPS_DIR/build
    if [ ! -d "$BUILD_DIR" ]; then
        mkdir -p "$BUILD_DIR"
    fi

    # Compile and install all dependencies.

    source $CURRENT_DIR/install-deps/libccd/install-libccd.sh
    source $CURRENT_DIR/install-deps/mujoco/install-mujoco.sh

    # Print all environment variables.

    echo
    echo "export C_INCLUDE_PATH=$C_INCLUDE_PATH"
    echo
    echo "export CPLUS_INCLUDE_PATH=$CPLUS_INCLUDE_PATH"
    echo
    echo "export LIBRARY_PATH=$LIBRARY_PATH\n"
    echo
    echo "export CMAKE_PREFIX_PATH=$CMAKE_PREFIX_PATH"
    echo
    echo "export LD_LIBRARY_PATH=$LD_LIBRARY_PATH"
    echo
    echo "export PATH=$PATH"
    echo
    echo "export DST_DIR=$DEPS_DIR/dst"
    echo
}

install-all
