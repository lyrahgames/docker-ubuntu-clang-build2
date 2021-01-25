ARG UBUNTU_VERSION=latest

# Base Stage
FROM ubuntu:${UBUNTU_VERSION} AS base
ARG CLANG_VERSION=10
RUN \
  echo "CLANG_VERSION=$CLANG_VERSION" && \
  apt-get update && \
  apt-get install -y \
    # Install required version of clang tools.
    clang-$CLANG_VERSION \
    clang-tools-$CLANG_VERSION \
    clang-tidy-$CLANG_VERSION \
    clang-format-$CLANG_VERSION \
    # build2 Toolchain Dependencies
    curl \
    wget \
    openssl \
    # Git is needed for CI environments.
    git \
  && \
  rm -rf /var/lib/apt/lists/* && \
  # Set the default Clang version used
  # when calling 'clang', 'cc', 'clang++', 'c++', etc.
  update-alternatives --install /usr/bin/clang clang /usr/bin/clang-$CLANG_VERSION 10 && \
  update-alternatives --install /usr/bin/cc cc /usr/bin/clang 20 && \
  update-alternatives --set cc /usr/bin/clang && \
  update-alternatives --install /usr/bin/clang++ clang++ /usr/bin/clang++-$CLANG_VERSION 10 && \
  update-alternatives --install /usr/bin/c++ c++ /usr/bin/clang++ 20 && \
  update-alternatives --set c++ /usr/bin/clang++ && \
  update-alternatives --install /usr/bin/clang-tidy clang-tidy /usr/bin/clang-tidy-$CLANG_VERSION 10 && \
  update-alternatives --install /usr/bin/clang-format clang-format /usr/bin/clang-format-$CLANG_VERSION 10

# build2 Build Stage
FROM base AS builder
ARG BUILD2_VERSION=0.13.0
RUN \
  echo "BUILD2_VERSION=$BUILD2_VERSION" && \
  apt-get update && \
  apt-get install -y \
    # To bootstrap the build2 toolchain more efficiently,
    # Make has to be installed.
    make \
  && \
  rm -rf /var/lib/apt/lists/* && \
  curl -sSfO https://download.build2.org/$BUILD2_VERSION/build2-install-$BUILD2_VERSION.sh && \
  sh build2-install-$BUILD2_VERSION.sh --cxx clang++ --yes --sudo false --no-check --trust yes /opt/build2

# Deployment Stage
FROM base AS deployer
# To keep the links for the build2 shared libraries,
# we have to copy the build2 toolchain to same destination.
COPY --from=builder /opt/build2 /opt/build2
ENV PATH "/opt/build2/bin:$PATH"
LABEL maintainer="lyrahgames@mailbox.org"
