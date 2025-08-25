#!/usr/bin/env bash

# Copyright 2025 Genesis Corporation
#
# All Rights Reserved.
#
#    Licensed under the Apache License, Version 2.0 (the "License"); you may
#    not use this file except in compliance with the License. You may obtain
#    a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#    WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#    License for the specific language governing permissions and limitations
#    under the License.

set -eu
set -x
set -o pipefail

INSTALL_PATH="/opt/"
WORK_DIR="/opt/gci_flutter_build_base"
FLUTTER_SDK_PATH="/opt/flutter"
BUILD_TARGET="${UI_BUILD_ENV_BUILD_TARGET:-ci_stage}"
FLUTTER_SDK_VERSION="3.35.1"
JDK_URL="https://download.oracle.com/java/21/latest/jdk-21_linux-x64_bin.deb"
ANDROID_CLI_TOOLS="commandlinetools-linux-13114758_latest"
ANDROID_CLI_TOOLS_URL="https://dl.google.com/android/repository/$ANDROID_CLI_TOOLS.zip"
ANDROID_SDK_PATH="$INSTALL_PATH/android-sdk"
USER="ubuntu"

[[ "$EUID" == 0 ]] || exec sudo -s "$0" "$@"

apt update
apt install -y jq zip \
    libc6:amd64 libstdc++6:amd64 lib32z1 libbz2-1.0:amd64 # for Android

# Install FVM
export FVM_ALLOW_ROOT=true
curl -fsSL https://fvm.app/install.sh | bash

cd "/tmp"
wget -q "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_$FLUTTER_SDK_VERSION-stable.tar.xz"
tar -xf "flutter_linux_$FLUTTER_SDK_VERSION-stable.tar.xz" -C "$INSTALL_PATH"

ln -sv "$FLUTTER_SDK_PATH/bin/flutter" "/usr/local/bin/flutter"

# Install Java
cd "/tmp"
wget -q "$JDK_URL"
apt install -y ./jdk-21_linux-x64_bin.deb

# Prepare the environment
cd "$WORK_DIR"
mv genesis/images/make_ui_build_env.py /usr/local/bin/make_ui_build_env
chmod +x /usr/local/bin/make_ui_build_env

# Install Android SDK
mkdir -p "$ANDROID_SDK_PATH/cmdline-tools/latest"
cd "/tmp"
wget -q "$ANDROID_CLI_TOOLS_URL"
unzip "$ANDROID_CLI_TOOLS.zip"
cd cmdline-tools
mv * "$ANDROID_SDK_PATH/cmdline-tools/latest/"
echo "export ANDROID_HOME=$ANDROID_SDK_PATH" >> /home/$USER/.bashrc
echo "export PATH=$PATH:$ANDROID_SDK_PATH/cmdline-tools/latest/bin" >> /home/$USER/.bashrc

# Install Android SDK Command Line Tools
export ANDROID_HOME="$ANDROID_SDK_PATH"
$ANDROID_SDK_PATH/cmdline-tools/latest/bin/sdkmanager "platforms;android-35" "build-tools;35.0.0" "platform-tools" <<EOF
y
EOF
chown -R $USER:$USER $ANDROID_SDK_PATH
