#!/bin/bash

# Starts node server which will handle (.tsv) list update
# Opens the browser (if configured)

# Stricter Bash mode: Exit on error, Exit on missing variable, Exit when anything in pipe errors
set -euo pipefail

DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Load configuration
source "${DIR}/dl-helper.env"

REQUIRED_TOOLS=(npm "${BROWSER}")
missing_tools=()
for tool in "${REQUIRED_TOOLS[@]}"; do
	if ! command -v "${tool}" >/dev/null 2>&1; then
		missing_tools+=("${tool}")
	fi
done

if [[ ${#missing_tools[@]} -gt 0 ]]; then
	echo >&2 "Error: Missing required tool(s): ${missing_tools[*]}"
	exit 1
fi

EXT="tsv"
SRC="$(find "${DIR}/listing" -maxdepth 1 -type d | sort -r | head -n 1)"
PORT=3000
DELAY=5

rawName="${SRC}/list-clean"

if [[ ! -f "${rawName}.org" ]]; then
	echo "Backing up as ${rawName}.org"
	cp "${SRC}/list-clean.${EXT}" "${rawName}.org"
else
	echo "Backup already exists"
fi

BROWSER_OPTS+=("http://localhost:${PORT}")

if [[ -n "${BROWSER}" ]]; then
	sleep ${DELAY} && echo "Launching browser..." && "${BROWSER}" "${BROWSER_OPTS[@]}" &
else
	echo "No browser configured - help yourself:"
	echo "http://localhost:${PORT}"
fi

echo "Launching server..."
pushd "${DIR}/dl-helper"

npm start "${rawName}.${EXT}" -p "${PORT}"

popd
