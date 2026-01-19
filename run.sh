#!/bin/bash

# (1) Exit on error
# (2) Fail on unset variables
# (3) Fail on pipe failure
set -euo pipefail

# Load nvm (path may vary!)
export NVM_DIR="$HOME/.nvm"
if [ -s "$NVM_DIR/nvm.sh" ]; then
  # Load nvm
  . "$NVM_DIR/nvm.sh"
else
  echo "❌ nvm not found. Please install nvm first."
  exit 1
fi

################################################################################

# Setup the package
if [ "${1:-}" = "setup" ]; then
    echo "1. Cleaning temporary files..."
    rm -rf node_modules
    rm -rf dist

    echo "2. Initializing submodules..."
    git submodule update --init --recursive

    BRANCH_NAME=$(git config -f .gitmodules submodule.dependencies/llvm.branch-ref)
    if [ ! -z "$BRANCH_NAME" ]; then
        echo ">> Checking out branch ${BRANCH_NAME}..."
        pushd dependencies/llvm
            git checkout ${BRANCH_NAME}
        popd
    fi

    EXPECTED_NODE_VERSION=$(cat .nvmrc)
    NODE_VERSION=$(node --version)

    echo "3. Checking Node.js version (${EXPECTED_NODE_VERSION})..."
    if [ "$NODE_VERSION" != "$EXPECTED_NODE_VERSION" ]; then
        echo "❌ Node.js version mismatch. Please use the correct version of Node.js ($EXPECTED_NODE_VERSION)."
        exit 1
    fi

    echo "4. Installing package dependencies..."
    npm install --silent
    exit 0
fi

################################################################################

if [ "${1:-}" = "clean" ]; then
    echo "1. Cleaning the package..."
    npx --no-install mimi-pkg clean
    exit 0
fi

################################################################################

if [ "${1:-}" = "build" ]; then
    PRESET_NAME=${2:-}
    echo "1. Building the package (${PRESET_NAME})..."
    npx --no-install dotenv -e .env -- npx --no-install mimi-pkg build ${PRESET_NAME}
    exit 0
fi

if [ "${1:-}" = "bundle" ]; then
    PRESET_NAME=${2:-}
    echo "1. Bundling the package (${PRESET_NAME})..."
    npx --no-install dotenv -e .env -- npx --no-install mimi-pkg bundle ${PRESET_NAME}
    exit 0
fi

if [ "${1:-}" = "deploy" ]; then
    PRESET_NAME=${2:-}
    echo "1. Deploying the package (${PRESET_NAME})..."
    npx --no-install dotenv -e .env -- npx --no-install mimi-pkg deploy ${PRESET_NAME}
    exit 0
fi

################################################################################

echo "Usage: run.sh <command> <args...>"
echo "Commands:"
echo "> run.sh setup              - Cleans the package and installs dependencies."
echo "> run.sh clean              - Cleans the package and temporary files."
echo "> run.sh build <preset>     - Builds the package given a CMake preset."
echo "> run.sh bundle <preset>    - Bundles the package given a CMake preset."
echo "> run.sh deploy <preset>    - Deploys the package given a CMake preset."
exit 1