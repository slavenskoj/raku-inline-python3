#!/usr/bin/env bash

# Inline::Pythonic pyenv setup script

set -e

echo "=== Inline::Pythonic pyenv Setup ==="
echo

# Check if pyenv is installed
if ! command -v pyenv &> /dev/null; then
    echo "❌ pyenv is not installed!"
    echo
    echo "Please install pyenv first:"
    echo
    case "$OSTYPE" in
        darwin*)
            echo "  brew install pyenv"
            ;;
        linux*)
            echo "  curl https://pyenv.run | bash"
            ;;
        *)
            echo "  See: https://github.com/pyenv/pyenv#installation"
            ;;
    esac
    echo
    echo "Then add to your shell configuration:"
    echo '  export PYENV_ROOT="$HOME/.pyenv"'
    echo '  export PATH="$PYENV_ROOT/bin:$PATH"'
    echo '  eval "$(pyenv init -)"'
    exit 1
fi

echo "✅ pyenv is installed: $(which pyenv)"
echo

# Check PYENV_ROOT
if [ -z "$PYENV_ROOT" ]; then
    echo "⚠️  PYENV_ROOT is not set. Setting to default..."
    export PYENV_ROOT="$HOME/.pyenv"
fi

echo "✅ PYENV_ROOT: $PYENV_ROOT"
echo

# Check Python version
REQUIRED_VERSION="3.11.5"
CURRENT_VERSION=$(pyenv version-name 2>/dev/null || echo "none")

if [ "$CURRENT_VERSION" = "none" ] || [ "$CURRENT_VERSION" = "system" ]; then
    echo "❌ No Python version set in pyenv"
    echo
    echo "Installing Python $REQUIRED_VERSION..."
    pyenv install -s $REQUIRED_VERSION
    pyenv local $REQUIRED_VERSION
    echo "✅ Python $REQUIRED_VERSION installed and set locally"
else
    echo "✅ Current Python version: $CURRENT_VERSION"
    
    # Check if it meets minimum requirements
    MAJOR=$(echo $CURRENT_VERSION | cut -d. -f1)
    MINOR=$(echo $CURRENT_VERSION | cut -d. -f2)
    
    if [ "$MAJOR" -eq 3 ] && [ "$MINOR" -ge 8 ]; then
        echo "✅ Python version meets requirements (3.8+)"
    else
        echo "❌ Python version too old (requires 3.8+)"
        echo
        echo "Installing Python $REQUIRED_VERSION..."
        pyenv install -s $REQUIRED_VERSION
        pyenv local $REQUIRED_VERSION
        echo "✅ Python $REQUIRED_VERSION installed and set locally"
    fi
fi

echo
echo "=== Setup Complete ==="
echo
echo "You can now install Inline::Pythonic with:"
echo "  zef install ."
echo
echo "Or test it with:"
echo "  zef test ."