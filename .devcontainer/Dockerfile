ARG VARIANT="bullseye"
FROM mcr.microsoft.com/vscode/devcontainers/rust:0-${VARIANT}

# [Optional] Uncomment this section to install additional packages.
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends cmake

# DFINITY Canister smart contract SDK
RUN sh -ci "$(curl -fsSL https://internetcomputer.org/install.sh)"

# rust dfinity utility
# this command takes lot of time and resources,
# after the first time the container is built, try not to edit steps before to keep it cached
# and add new steps after this one
RUN cargo install ic-cdk-optimizer

# install wasm32-unknown-unknown
# https://internetcomputer.org/docs/current/developer-docs/build/cdks/cdk-rs-dfinity/rust-quickstart#register-build-and-deploy-your-project
RUN rustup target add wasm32-unknown-unknown