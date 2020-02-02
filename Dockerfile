FROM ubuntu:18.04

# LABEL Robson Oliveira dos Santos <robsonos@outlook.com>

# -----------------------------------------------------------------------------
# Environment variables
# -----------------------------------------------------------------------------
ENV \
    # GIT_EMAIL="robsonos@outlook.com" \
    # GIT_NAME="Robson Oliveira dos Santos" \
    ANDROID_BUILD_TOOLS_VERSION=29.0.3 \
    ANDROID_PLATFORMS_TOOLS_VERSION="29.0.5" \
    ANDROID_PLATFORMS="android-10" \
    NODE_VERSION=12.14.1 \
    NPM_VERSION=6.13.4 \
    IONIC_VERSION=5.4.15 \
    CORDOVA_VERSION=9.0.0 \
    GRADLE_VERSION=5.6.2 \
    ANDROID_SDK_ROOT=/opt/android-sdk-linux \
    NG_CLI_ANALYTICS=ci\
    CI=true
# DEBIAN_FRONTEND=noninteractive

# -----------------------------------------------------------------------------
# PATH
# -----------------------------------------------------------------------------
ENV PATH ${PATH}:${ANDROID_SDK_ROOT}/tools:${ANDROID_SDK_ROOT}/tools/bin:${ANDROID_SDK_ROOT}/platform-tools:/usr/local/gradle-${GRADLE_VERSION}/bin
# export PATH=${PATH}:/opt/android-sdk-linux/tools:/opt/android-sdk-linux/tools/bin:/opt/android-sdk-linux/platform-tools:/usr/local/gradle-5.6.2/bin

# -----------------------------------------------------------------------------
# Apt-mirror and Java8 and extra packages
# -----------------------------------------------------------------------------
RUN \
    sed -i 's|http://archive|http://au.archive|g' /etc/apt/sources.list && \
    apt-get update && \
    apt-get install -y openjdk-8-jdk aria2 unzip --no-install-recommends && \
    rm -rf /var/lib/apt/lists/*

# -----------------------------------------------------------------------------
# Gradle
# -----------------------------------------------------------------------------
RUN \
    cd /usr/local && \
    aria2c -q -x 16 -s 16 https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip && \
    unzip -o -qq gradle-${GRADLE_VERSION}-bin.zip && \
    rm gradle-${GRADLE_VERSION}-bin.zip

# -----------------------------------------------------------------------------
# Sdk tools, platform-tools and build-tools
# -----------------------------------------------------------------------------
RUN \
    mkdir -p ${ANDROID_SDK_ROOT} && \
    cd ${ANDROID_SDK_ROOT} && \
    aria2c -q -x 16 -s 16 https://dl.google.com/android/repository/sdk-tools-linux-4333796.zip && \
    aria2c -q -x 16 -s 16 https://dl.google.com/android/repository/build-tools_r$ANDROID_BUILD_TOOLS_VERSION-linux.zip && \
    for i in ${ANDROID_BUILD_TOOLS_VERSION}; do aria2c -q -x 16 -s 16 https://dl.google.com/android/repository/platform-tools_r$i-linux.zip; done && \
    for i in *.zip; do unzip -o -qq $i && rm $i; done

# -----------------------------------------------------------------------------
# Android licenses and SDK Manager
# -----------------------------------------------------------------------------
RUN \
    yes | sdkmanager --licenses && \
    mkdir -p .android && touch ~/.android/repositories.cfg && \
    sdkmanager "platform-tools" && \
    for i in ${ANDROID_BUILD_TOOLS_VERSION}; do sdkmanager "build-tools;$i"; done && \
    for i in ${ANDROID_PLATFORMS}; do sdkmanager "platforms;$i"; done

# -----------------------------------------------------------------------------
# Node and Node packages
# -----------------------------------------------------------------------------
RUN \
    aria2c -q -x 16 -s 16 "http://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-x64.tar.gz" && \
    tar -xf "node-v$NODE_VERSION-linux-x64.tar.gz" -C /usr/local --strip-components=1 && \
    rm "node-v$NODE_VERSION-linux-x64.tar.gz" && \
    npm install -g npm@"$NPM_VERSION" cordova@"$CORDOVA_VERSION" ionic@"$IONIC_VERSION"

# -----------------------------------------------------------------------------
# Versions
# -----------------------------------------------------------------------------
RUN \
    node -v && \
    npm -v && \
    ionic -v && \
    cordova -v && \
    gradle -v

# -----------------------------------------------------------------------------
# Build an ionic project once
# -----------------------------------------------------------------------------
RUN cd ~ && \
    ionic start ionic blank --type=angular && \
    cd ionic && \
    ionic cordova build android --no-telemetry && \
    cd .. && \
    rm -R ionic

# -----------------------------------------------------------------------------
# Clean-up
# -----------------------------------------------------------------------------
RUN \
    apt-get remove --purge -y aria2 unzip && \
    apt-get autoremove -y && \
    apt-get autoclean -y && \
    npm cache clear --force

# -----------------------------------------------------------------------------
# Workspace
# -----------------------------------------------------------------------------
RUN mkdir /workspace
WORKDIR /workspace
# COPY . /workspace/
