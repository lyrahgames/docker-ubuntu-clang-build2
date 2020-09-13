ARG GCC_BUILDER_VERSION=latest
ARG UBUNTU_VERSION=latest

FROM gcc:${GCC_BUILDER_VERSION} AS builder
ARG BUILD2_VERSION=0.13.0
RUN \
  curl -sSfO https://download.build2.org/$BUILD2_VERSION/build2-install-$BUILD2_VERSION.sh && \
  sh build2-install-$BUILD2_VERSION.sh --yes --sudo false --no-check --trust yes /opt/build2


FROM ubuntu:${UBUNTU_VERSION} AS deployer
ARG CLANG_VERSION=10
RUN \
  echo "CLANG_VERSION=$CLANG_VERSION" && \
  apt-get update && \
  apt-get install -y \
    clang-$CLANG_VERSION \
    clang-tools-$CLANG_VERSION \
    clang-tidy-$CLANG_VERSION \
    clang-format-$CLANG_VERSION \
    curl \
    wget \
    openssl \
    git \
  && \
  rm -rf /var/lib/apt/lists/* && \
  update-alternatives --install /usr/bin/clang clang /usr/bin/clang-$CLANG_VERSION 10 && \
  update-alternatives --install /usr/bin/cc cc /usr/bin/clang 20 && \
  update-alternatives --set cc /usr/bin/clang && \
  update-alternatives --install /usr/bin/clang++ clang++ /usr/bin/clang++-$CLANG_VERSION 10 && \
  update-alternatives --install /usr/bin/c++ c++ /usr/bin/clang++ 20 && \
  update-alternatives --set c++ /usr/bin/clang++ && \
  update-alternatives --install /usr/bin/clang-tidy clang-tidy /usr/bin/clang-tidy-$CLANG_VERSION 10 && \
  update-alternatives --install /usr/bin/clang-format clang-format /usr/bin/clang-format-$CLANG_VERSION 10
COPY --from=builder /opt/build2 /opt/build2
ENV PATH "/opt/build2/bin:$PATH"
LABEL maintainer="lyrahgames@mailbox.org"