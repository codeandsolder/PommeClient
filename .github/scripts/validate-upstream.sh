#!/usr/bin/env bash
set -euo pipefail
git submodule update --init --recursive
sudo apt-get update
sudo apt-get install -y --no-install-recommends libvulkan-dev libxkbcommon-dev libwayland-dev libasound2-dev libudev-dev libdbus-1-dev libwebkit2gtk-4.1-dev libappindicator3-dev librsvg2-dev patchelf libfreetype-dev
# Derive the portable workspace from the candidate rather than freezing its
# package list. Mobile targets and the two client profiles have separate checks.
metadata=$(cargo metadata --locked --no-deps --format-version 1)
mapfile -t packages < <(jq -r '.workspace_members[] as $id | .packages[] | select(.id == $id) | .name' <<< "$metadata")
(( ${#packages[@]} > 0 ))
host=()
for package in "${packages[@]}"; do
  cargo fmt -p "$package" -- --check
  case "$package" in
    pomme-android|pomme-ios|pomme-client|pomme-singleplayer) ;;
    *) host+=(-p "$package");;
  esac
done
(( ${#host[@]} > 0 ))
cargo clippy --locked "${host[@]}" --release --all-targets -- -D warnings
cargo clippy --locked -p pomme-protocol -p pomme-auth --release --all-targets --all-features -- -D warnings
cargo test --locked "${host[@]}"
cargo clippy --locked -p pomme-client --release --all-targets --no-default-features --features test-harness,cpu-bench -- -D warnings
cargo test --locked -p pomme-client --release --no-default-features
cargo check --manifest-path third_party/SteelMC/Cargo.toml -p steel-utils --release --locked
cargo clippy --locked -p pomme-singleplayer -p pomme-client --release --all-targets -- -D warnings
cargo test --locked -p pomme-singleplayer --release -- --include-ignored
