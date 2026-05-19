#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="${REPO_ROOT}/_build"
TEMPLATES="${REPO_ROOT}/scripts/templates"

rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}/_layouts"

cp "${TEMPLATES}/_config.yml" "${BUILD_DIR}/_config.yml"
cp "${TEMPLATES}/_layouts/default.html" "${BUILD_DIR}/_layouts/default.html"

INDEX_FILE="${BUILD_DIR}/index.md"
{
  echo "---"
  echo "layout: default"
  echo "title: UT-URTraining"
  echo "---"
  echo ""
  echo "# UT Undergrad Research Training"
  echo ""
} > "${INDEX_FILE}"

ALLOW_EXTS=(png jpg jpeg gif svg webp pdf mp4 webm mov m4v ico bmp)
FIND_NAME_ARGS=()
for ext in "${ALLOW_EXTS[@]}"; do
  if (( ${#FIND_NAME_ARGS[@]} )); then
    FIND_NAME_ARGS+=(-o)
  fi
  FIND_NAME_ARGS+=(-iname "*.${ext}")
done

shopt -s nullglob
for dir in "${REPO_ROOT}"/*/; do
  folder="$(basename "${dir}")"

  case "${folder}" in
    .*|_build|_site|scripts|node_modules|vendor) continue ;;
  esac

  readme="${dir}README.md"
  [[ -f "${readme}" ]] || continue

  title="$(grep -m1 '^# ' "${readme}" | sed 's/^# *//' || true)"
  [[ -z "${title}" ]] && title="${folder}"

  mkdir -p "${BUILD_DIR}/${folder}"

  {
    echo "---"
    echo "layout: default"
    echo "title: ${title//\"/\\\"}"
    echo "---"
    cat "${readme}"
  } > "${BUILD_DIR}/${folder}/index.md"

  while IFS= read -r -d '' abspath; do
    relpath="${abspath#${dir}}"
    target="${BUILD_DIR}/${folder}/${relpath}"
    mkdir -p "$(dirname "${target}")"
    cp "${abspath}" "${target}"
  done < <(find "${dir}" -type f \( "${FIND_NAME_ARGS[@]}" \) -print0)

  echo "- [${title}](./${folder})" >> "${INDEX_FILE}"
  echo "staged: ${folder} -> /${folder}/  (title: ${title})"
done

echo ""
echo "Build staged at ${BUILD_DIR}"
