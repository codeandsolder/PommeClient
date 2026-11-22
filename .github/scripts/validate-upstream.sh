#!/usr/bin/env bash
set -euo pipefail
git submodule update --init --recursive
sudo apt-get update
sudo apt-get install -y --no-install-recommends libvulkan-dev libxkbcommon-dev libwayland-dev libasound2-dev libudev-dev libdbus-1-dev libwebkit2gtk-4.1-dev libappindicator3-dev librsvg2-dev patchelf
# Match the Linux client, launcher and singleplayer checks in ordinary CI.
for package in pomme-client pomme-protocol pomme-dirs pomme-auth pomme-install pomme-singleplayer pomme-launcher pomme-android pomme-ios; do
  cargo fmt -p "$package" -- --check
done
cargo clippy --locked -p pomme-client --release --all-targets --no-default-features -- -D warnings
cargo clippy --locked -p pomme-protocol -p pomme-dirs -p pomme-auth -p pomme-install --release --all-targets --all-features -- -D warnings
cargo test --locked -p pomme-protocol -p pomme-dirs -p pomme-auth -p pomme-install
cargo test --locked -p pomme-client --release --no-default-features
cargo check --manifest-path third_party/SteelMC/Cargo.toml -p steel-utils --release --locked
cargo clippy --locked -p pomme-singleplayer -p pomme-client --release --all-targets -- -D warnings
cargo test --locked -p pomme-singleplayer --release -- --include-ignored
cargo clippy --locked -p pomme-launcher --release --all-targets --all-features -- -D warnings
cargo run --locked -p pomme-launcher --quiet --bin generate-bindings
