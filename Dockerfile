# FROM rust:1.60 as dependencies
# WORKDIR /app
# COPY Cargo.toml .
# RUN rustup default nightly-2019-01-29 && \
#     mkdir -p src && \
#     echo "fn main() {}" > src/main.rs && \
#     cargo build -Z unstable-options --out-dir /output
# 
# 
# FROM rust:1.60 as builder
# WORKDIR /app
# COPY --from=dependencies /app/Cargo.toml .
# COPY --from=dependencies /usr/local/cargo /usr/local/cargo
# COPY . .
# VOLUME /output
# 
# 
# 
# FROM alpine:latest
# COPY --from=builder /etc/passwd /etc/passwd
# COPY --from=builder /etc/group /etc/group
# WORKDIR /app
# COPY --from=builder /app/target/release/rustdesk-server /app
# CMD IP=$IP /app/rustdesk-server

FROM lukemathwalker/cargo-chef:latest-rust-1.60.0 AS chef
WORKDIR app

FROM chef AS planner
COPY . .
RUN cargo chef prepare --recipe-path recipe.json

FROM chef AS builder
COPY --from=planner /app/recipe.json recipe.json
# Build dependencies - this is the caching Docker layer!
RUN cargo chef cook --release --recipe-path recipe.json
# Build application
COPY . .
RUN cargo build --release
RUN ls /app/target/release

# We do not need the Rust toolchain to run the binary!
FROM debian:buster-slim AS runtime
WORKDIR app


COPY --from=builder /app/target/release/rustdesk-server /usr/local/bin
CMD IP=$IP rustdesk-server
