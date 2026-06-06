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

# On Windows (Git Bash / MSYS) the Ninja generator needs the MSVC toolchain in
# the environment (cl, INCLUDE, LIB, ...). Unlike the Visual Studio generator it
# won't bootstrap it, so auto-import vcvars64 here — no shell-profile changes.
# No-ops on macOS/Linux and when already run from a VS developer shell.
ensure_msvc_env() {
  case "$(uname -s)" in
    MINGW*|MSYS*|CYGWIN*) ;;
    *) return 0 ;;
  esac
  if command -v cl > /dev/null 2>&1; then
    return 0
  fi

  local vswhere="/c/Program Files (x86)/Microsoft Visual Studio/Installer/vswhere.exe"
  if [ ! -x "$vswhere" ]; then
    echo "❌ Visual Studio not found (vswhere missing). Install VS 2022 with the 'Desktop development with C++' workload."
    exit 1
  fi

  local vsroot vcvars_w bat line name value
  vsroot=$("$vswhere" -latest -products '*' \
    -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 \
    -property installationPath | tr -d '\r')
  vcvars_w=$(cygpath -w "$(cygpath -u "$vsroot")/VC/Auxiliary/Build/vcvars64.bat")
  if [ ! -f "$(cygpath -u "$vcvars_w")" ]; then
    echo "❌ vcvars64.bat not found under: $vsroot"
    exit 1
  fi

  echo ">> Importing MSVC environment (vcvars64)..."
  # Run vcvars in a temp .bat (sidesteps MSYS quote-mangling of the spaced path),
  # then import the resulting environment. Strip CR from cmd's CRLF output, and
  # convert the Windows PATH list back to POSIX form.
  bat="_vcvars_env_$$.bat"
  printf '@echo off\r\ncall "%s"\r\nset\r\n' "$vcvars_w" > "$bat"
  while IFS= read -r line; do
    line=${line%$'\r'}
    name=${line%%=*}; value=${line#*=}
    case "$name" in ''|*[!A-Za-z0-9_]*) continue;; esac
    if [ "$name" = "PATH" ] || [ "$name" = "Path" ]; then
      export PATH="$(cygpath -up "$value")"
    else
      export "$name=$value"
    fi
  done < <(cmd //c "$bat")
  rm -f "$bat"

  if ! command -v cl > /dev/null 2>&1; then
    echo "❌ Failed to import the MSVC environment (cl not found after vcvars64)."
    exit 1
  fi
}

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
    ensure_msvc_env
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