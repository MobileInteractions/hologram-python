#!/bin/bash
# Author: Hologram <support@hologram.io>
#
# Copyright 2016 - Hologram (Konekt, Inc.)
#
# LICENSE: Distributed under the terms of the MIT License
#
# update.sh - This file helps update this Python SDK and all required dependencies
#              on a machine.

set -euo pipefail

required_programs=('python3' 'pip3' 'ps' 'kill' 'libpython3.9-dev')
OS=''

# Check OS.
if [ "$(uname)" == "Darwin" ]; then

    echo 'Darwin system detected'
    OS='DARWIN'

elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then

    echo 'Linux system detected'
    OS='LINUX'
    required_programs+=('ip' 'pppd')

elif [ "$(expr substr $(uname -s) 1 10)" == "MINGW32_NT" ]; then

    echo 'Windows 32-bit system detected'
    OS='WINDOWS'

elif [ "$(expr substr $(uname -s) 1 10)" == "MINGW64_NT" ]; then

    echo 'Windows 64-bit system detected'
    OS='WINDOWS'
fi

# Error out on unsupported OS.
if [ "$OS" == 'DARWIN' ] || [ "$OS" == 'WINDOWS' ]; then
    echo "$OS is not supported right now"
    exit 1
fi

function pause() {
    read -p "$*"
}

function install_software() {
    if [ "$OS" == 'LINUX' ]; then
        sudo apt -y install "$*"
    elif [ "$OS" == 'DARWIN' ]; then
        brew install "$*"
        echo 'TODO: macOS should go here'
    elif [ "$OS" == 'WINDOWS' ]; then
        echo 'TODO: windows should go here'
    fi
}

function check_python_version() {
    if ! python3 -V | grep '3.[7-9].[0-9]' > /dev/null 2>&1; then
        echo "An unsupported version of python 3 is installed. Must have python 3.7+ installed to use the Hologram SDK"
        exit 1
    fi
}

# EFFECTS: Returns true if the specified program is installed, false otherwise.
function check_if_installed() {
    if command -v "$*" >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

function update_repository() {
    if [ "$OS" == 'LINUX' ]; then
        sudo apt update
    elif [ "$OS" == 'DARWIN' ]; then
        brew update
        echo 'TODO: macOS should go here'
    elif [ "$OS" == 'WINDOWS' ]; then
        echo 'TODO: windows should go here'
    fi
}

# EFFECTS: Verifies that all required software is installed.
function verify_installation() {
    echo 'Verifying that all dependencies are installed correctly...'
    # Verify pip packages
    INSTALLED_PIP_PACKAGES="$(pip3 list)"

    if ! [[ "$INSTALLED_PIP_PACKAGES" == *"python-sdk-auth"* ]]; then
        echo 'Cannot find python-sdk-auth. Please rerun the install script.'
        exit 1
    fi

    if ! [[ "$INSTALLED_PIP_PACKAGES" == *"hologram-python"* ]]; then
        echo 'Cannot find hologram-python. Please rerun the install script.'
        exit 1
    fi

    echo 'You are now ready to use the Hologram Python SDK!'
}

check_python_version

update_repository

# Check if an older version exists and uninstall it
if command hologram version | grep '0.[0-8]'; then
    echo "Found a previous version of the SDK on Python 2. The new update uses"
    echo "Python 3 and is not compatible with Python 2. This script will uninstall"
    echo "the previous SDK version, install Python 3 and then install the new"
    echo "Python 3 version of the SDK. It will not make Python 3 your default"
    echo "Python version."
    pause "Press [Enter] key to continue...";
    sudo pip uninstall -y hologram-python
fi

# Iterate over all programs to see if they are installed
# Installs them if necessary
for program in ${required_programs[*]}
do
    if [ "$program" == 'pppd' ]; then
        if ! check_if_installed "$program"; then
            pause "Installing $program. Press [Enter] key to continue...";
            install_software 'ppp'
        fi
    elif [ "$program" == 'pip3' ]; then
        if ! check_if_installed "$program"; then
            pause "Installing $program. Press [Enter] key to continue...";
            install_software 'python3-pip'
        fi
        if ! pip3 -V | grep '3.[7-9]' >/dev/null 2>&1; then
            echo "pip3 is installed for an unsupported version of python."
            exit 1
        fi
    elif check_if_installed "$program"; then
        echo "$program is already installed."
    else
        pause "Installing $program. Press [Enter] key to continue...";
        install_software "$program"
    fi
done

# Install SDK itself.
sudo pip3 install hologram-python --upgrade

verify_installation
