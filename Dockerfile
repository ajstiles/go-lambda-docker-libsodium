# Match AWS lambda environment: https://amzn.to/2UzWflN
FROM amazonlinux:2017.03

# Libsodium and Go versions to install
ARG LIBSODIUM_VERSION="libsodium-1.0.17"
ARG GO_VERSION="go1.11.5.linux-amd64"

# See also ARG BINARY_NAME and SHARED_BUILD_FOLDER below
# Definitions are after yum, libsodium and go installs
# so Docker images can be built incremementally after
# those LONG steps.
 
# Install prerequesites via yum
RUN yum update -y
RUN yum install -y zip gcc tar git

# Download and build libsodium, including shared object files (.so)
RUN \
    mkdir -p /tmpbuild/libsodium && \
    cd /tmpbuild/libsodium && \
    curl -L https://download.libsodium.org/libsodium/releases/$LIBSODIUM_VERSION.tar.gz -o $LIBSODIUM_VERSION.tar.gz && \
    tar xfvz $LIBSODIUM_VERSION.tar.gz && \
    cd /tmpbuild/libsodium/$LIBSODIUM_VERSION/ && \
    ./configure && \
    make && make check && \
    make install && \
    mv src/libsodium /usr/local/ && \
    rm -Rf /tmpbuild/ 

# Install Go and set GOPATH and PATH
RUN \
    curl -O https://storage.googleapis.com/golang/$GO_VERSION.tar.gz && \
    tar -C /usr/local -xzf $GO_VERSION.tar.gz && \
    mkdir -p ~/go/bin
ENV GOPATH "$HOME/go"
ENV PATH "$PATH:/usr/local/go/bin:~/go/bin"

# Required for jamesruan/sodium to load libsodium.so
ENV PKG_CONFIG_PATH "/usr/local/lib/pkgconfig/"

# Get project dependencies. SOMEDAY - Use go modules
RUN go get "github.com/aws/aws-lambda-go/lambda"
RUN go get "github.com/jamesruan/sodium"

# Setup /app working directory
RUN mkdir /app 
WORKDIR /app

# Copy libsodium to lib directory for deployment package structure
RUN mkdir lib
RUN cp /usr/local/lib/libsodium.so.23.2.0 lib/
RUN cp /usr/local/lib/libsodium.so.23 lib/
RUN cp /usr/local/lib/libsodium.so lib/

#------------------------------------------------------------------------------
# Everything above this line will only run the first time you build the
# container. Subsequent builds only execute the steps below and *should* be
# fastish.

# Name of binary to build. Should match function name.
ARG BINARY_NAME

# Location to copy deployment package on completion so host can copy it.
ARG SHARED_BUILD_FOLDER=/build

# Name of deployment package
ARG PACKAGE_NAME="${BINARY_NAME}_handler.zip"

# Build handler binary
ADD main.go /app/
RUN GOOS=linux go build -o $BINARY_NAME main.go

# Build deployment package and copy to shared build folder
RUN zip $PACKAGE_NAME $BINARY_NAME lib/*
RUN mkdir -p $SHARED_BUILD_FOLDER
RUN cp $PACKAGE_NAME $SHARED_BUILD_FOLDER/
