#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="${REPO_ROOT}/_build"

bash "${REPO_ROOT}/scripts/build_pages.sh"

# Prefer Homebrew Ruby if installed (system Ruby 2.6 is too old for Jekyll 4).
# Pinning to 3.3 — ruby@4 needs a newer C SDK than Apple CLT currently ships.
for candidate in /opt/homebrew/opt/ruby@3.3 /opt/homebrew/opt/ruby@3.2 /opt/homebrew/opt/ruby; do
  if [[ -x "${candidate}/bin/ruby" ]]; then
    export PATH="${candidate}/bin:${PATH}"
    break
  fi
done

# Workaround: on macOS 26 + CLT 15.2, clang++ can't locate libc++ headers
# (eventmachine native extension fails with "iostream not found"). Point at the
# SDK's c++/v1 explicitly if it's there.
CPP_V1="$(xcrun --show-sdk-path 2>/dev/null)/usr/include/c++/v1"
if [[ -d "${CPP_V1}" ]]; then
  export CPLUS_INCLUDE_PATH="${CPP_V1}${CPLUS_INCLUDE_PATH:+:${CPLUS_INCLUDE_PATH}}"
fi

cat > "${BUILD_DIR}/Gemfile" <<'EOF'
source 'https://rubygems.org'
gem 'jekyll', '~> 4.3'
gem 'webrick'
EOF

cd "${BUILD_DIR}"

export BUNDLE_PATH="${REPO_ROOT}/vendor/bundle"
bundle install

echo ""
echo "Serving on http://localhost:4000/  (baseurl overridden to empty for local preview)"
bundle exec jekyll serve --baseurl '' --host 127.0.0.1 --port 4000
