#!/bin/bash
set -e

read_version() {
  grep 'version:' mix.exs | head -1 | sed 's/.*version: "\(.*\)".*/\1/'
}

abort_if_tagged() {
  local version=$1
  if git rev-parse "v$version" >/dev/null 2>&1; then
    echo "Tag v$version already exists, aborting"
    exit 1
  fi
}

check_gates() {
  echo "Running tests..."
  mix test || exit 1

  echo "Running linter..."
  mix lint || exit 1
}

create_tag() {
  local version=$1
  echo "Creating tag v$version..."
  git tag "v$version"
  git push origin "v$version"
}

create_release() {
  local version=$1
  echo "Creating GitHub release..."
  gh release create "v$version" \
    --title "elita $version" \
    --notes "el CLI via brew" \
    --target wip
}

compute_sha() {
  local version=$1
  echo "Computing sha256..."
  curl -sL "https://github.com/limadelic/elita/archive/refs/tags/v$version.tar.gz" | shasum -a 256 | awk '{print $1}'
}

update_tap() {
  local version=$1
  local sha=$2
  local temp_dir
  temp_dir=$(mktemp -d)

  cd "$temp_dir"
  git clone https://github.com/limadelic/homebrew-tap
  cd homebrew-tap

  sed -i '' "s|url.*github.com/limadelic/elita/archive.*|url \"https://github.com/limadelic/elita/archive/refs/tags/v${version}.tar.gz\"|" Formula/elita.rb
  sed -i '' "s|sha256.*|sha256 \"${sha}\"|" Formula/elita.rb

  git add Formula/elita.rb
  git commit -m "elita $version"
  git push origin main

  cd /
  rm -rf "$temp_dir"
}

main() {
  version=$(read_version)

  abort_if_tagged "$version"
  check_gates
  create_tag "$version"
  create_release "$version"
  sha=$(compute_sha "$version")
  update_tap "$version" "$sha"

  echo "Release complete: v$version"
}

main
