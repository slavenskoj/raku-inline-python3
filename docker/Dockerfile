# Multi-stage Dockerfile for Inline::Python3
# Supports both development and production builds

# Base stage with common dependencies
FROM ubuntu:22.04 AS base

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    gcc \
    g++ \
    make \
    cmake \
    git \
    curl \
    wget \
    libssl-dev \
    zlib1g-dev \
    libbz2-dev \
    libreadline-dev \
    libsqlite3-dev \
    libncurses5-dev \
    libncursesw5-dev \
    xz-utils \
    tk-dev \
    libffi-dev \
    liblzma-dev \
    python3-openssl \
    && rm -rf /var/lib/apt/lists/*

# Install Python 3.11
RUN apt-get update && apt-get install -y \
    python3.11 \
    python3.11-dev \
    python3.11-venv \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

# Set Python 3.11 as default
RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.11 1 \
    && update-alternatives --install /usr/bin/python python /usr/bin/python3.11 1

# Install Rakudo Star (includes Raku, zef, and common modules)
ENV RAKUDO_VERSION=2024.10
RUN cd /tmp \
    && wget https://github.com/rakudo/star/releases/download/$RAKUDO_VERSION/rakudo-star-$RAKUDO_VERSION-linux-x86_64-gcc.tar.gz \
    && tar xzf rakudo-star-$RAKUDO_VERSION-linux-x86_64-gcc.tar.gz \
    && cd rakudo-star-$RAKUDO_VERSION \
    && ./bin/rstar install -p /usr/local/rakudo \
    && cd / \
    && rm -rf /tmp/rakudo-star-*

# Add Rakudo to PATH
ENV PATH="/usr/local/rakudo/bin:/usr/local/rakudo/share/perl6/site/bin:${PATH}"

# Development stage - includes extra tools and Python packages
FROM base AS development

# Install development tools
RUN apt-get update && apt-get install -y \
    vim \
    nano \
    less \
    htop \
    strace \
    gdb \
    valgrind \
    python3-pytest \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

# Install Python development packages
RUN pip3 install --no-cache-dir \
    numpy \
    pandas \
    scipy \
    matplotlib \
    seaborn \
    scikit-learn \
    requests \
    beautifulsoup4 \
    ipython \
    jupyter \
    pytest \
    pytest-cov \
    black \
    pylint \
    mypy

# Install additional Raku modules for development
RUN zef install --force-install \
    Test::META \
    Test::When \
    Pod::To::Markdown \
    JSON::Fast \
    CSV::Parser

# Set working directory
WORKDIR /workspace

# Copy the project files
COPY . /workspace/

# Build the C library
RUN cd src && \
    gcc -shared -fPIC -o python3_helper.so python3_helper.c \
        $(python3-config --cflags) $(python3-config --ldflags) && \
    cp python3_helper.so ../resources/libraries/

# Install Inline::Python3
RUN zef install --force-install .

# Set up development environment
ENV PERL6LIB=/workspace/lib
ENV LD_LIBRARY_PATH=/workspace/resources/libraries:$LD_LIBRARY_PATH

# Default command for development
CMD ["/bin/bash"]

# Production stage - minimal image for running applications
FROM base AS production

# Install only necessary Python packages
RUN pip3 install --no-cache-dir \
    numpy \
    pandas \
    requests

# Create app directory
RUN mkdir -p /app
WORKDIR /app

# Copy only necessary files
COPY lib/ ./lib/
COPY src/ ./src/
COPY resources/ ./resources/
COPY META6.json ./

# Build the C library
RUN cd src && \
    gcc -shared -fPIC -o python3_helper.so python3_helper.c \
        $(python3-config --cflags) $(python3-config --ldflags) && \
    mkdir -p ../resources/libraries && \
    cp python3_helper.so ../resources/libraries/

# Install Inline::Python3
RUN zef install --force-install .

# Create non-root user
RUN useradd -m -s /bin/bash appuser && \
    chown -R appuser:appuser /app

USER appuser

# Set environment
ENV PERL6LIB=/app/lib
ENV LD_LIBRARY_PATH=/app/resources/libraries:$LD_LIBRARY_PATH

# Default command
CMD ["raku", "-e", "say 'Inline::Python3 container ready'"]

# Test stage - for running tests
FROM development AS test

# Install test dependencies
RUN zef install --force-install \
    Test::Output \
    Test::Mock

# Copy test files
COPY t/ ./t/

# Run tests by default
CMD ["prove", "-v", "-r", "--exec", "raku -I lib", "t/"]

# Builder stage - for building distributions
FROM development AS builder

# Install distribution building tools
RUN zef install --force-install \
    App::Mi6 \
    Distribution::Builder::MakeFromJSON

# Set up for building
WORKDIR /build
COPY . /build/

# Build distribution
RUN mi6 build

# The built distribution will be in /build/
CMD ["mi6", "dist"]