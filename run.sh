#!/bin/bash

# (1) Exit on error
# (2) Fail on unset variables
# (3) Fail on pipe failure
set -euo pipefail

# Load fnm
if command -v fnm > /dev/null 2>&1; then
  eval "$(fnm env)"
else
  echo "❌ fnm not found. Please install fnm first."
  exit 1
fi

################################################################################

# Setup the package
if [ "${1:-}" = "setup" ]; then
    echo "1. Cleaning temporary files..."
    rm -rf node_modules
    rm -rf dist

    EXPECTED_NODE_VERSION=$(cat .nvmrc)

    echo "2. Selecting Node.js version (${EXPECTED_NODE_VERSION})..."
    fnm use --install-if-missing

    NODE_VERSION=$(node --version)
    if [ "$NODE_VERSION" != "$EXPECTED_NODE_VERSION" ]; then
        echo "❌ Node.js version mismatch. Expected $EXPECTED_NODE_VERSION but got $NODE_VERSION."
        exit 1
    fi

    echo "3. Installing package dependencies..."
    npm install --silent

    echo "4. Initializing submodules..."
    git submodule update --init --recursive

    BRANCH_NAME=$(git config -f .gitmodules submodule.dependencies/llvm.branch-ref)
    if [ ! -z "$BRANCH_NAME" ]; then
        echo ">> Checking out branch ${BRANCH_NAME}..."
        pushd dependencies/llvm
            git checkout ${BRANCH_NAME}
        popd
    fi

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