#!/bin/bash

# Stricter Bash mode: Exit on error, Exit on missing variable, Exit when anything in pipe errors
set -euo pipefail

# Check required tools
REQUIRED_TOOLS=(xdg-user-dir xmllint wdiff colordiff)
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

DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Load configuration
source "${DIR}/dl-helper.env"


# download as txt ...
tStamp="$(date +"%Y-%m-%d_%H%M")"

SRC="$(xdg-user-dir DOWNLOAD)/${PLAYLIST_NAME} - YouTube.html"
WRK="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/listing/${tStamp}"

if [[ $# -gt 0 ]]; then
	SRC="${1}"
fi

if [[ ! -f "${SRC}" ]]; then
	echo >&2 "Save YouTube playlist as ${SRC} or provide path"
	exit 1
fi

mkdir -p "${WRK}"
targetRaw="${WRK}/list-raw.tsv"
targetClean="${WRK}/list-clean.tsv"
targetHTML="${WRK}/list-clean.html"

# Read video name
mapfile -t names < <(xmllint --html --nowarning --xpath "//ytd-playlist-video-list-renderer//h3//a/text()" "${SRC}" 2>/dev/null\
 | grep -v -E "^$|^[[:space:]]*$"\
 | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' -e 's/&amp;/\&/g'\
)

# Read video time
mapfile -t times < <(xmllint --html --nowarning --xpath "//ytd-playlist-video-list-renderer//ytd-thumbnail-overlay-time-status-renderer//badge-shape//text()" "${SRC}" 2>/dev/null\
 | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' -e '/^$/d'\
)

# Read channel name
mapfile -t channels < <(xmllint --html --nowarning --xpath "//ytd-playlist-video-list-renderer//ytd-channel-name//yt-formatted-string//text()" "${SRC}" 2>/dev/null\
 | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' -e '/^$/d'\
)



if [[ ${#names[@]} -ne ${#times[@]} || ${#names[@]} -ne ${#channels[@]} ]]; then
  echo >&2 "Line count mismatch: ${#names[@]} names, ${#times[@]} times and ${#channels[@]} channels"
  echo >&2 "Check for duplicate text"
  printf '%s\n' "${names[@]}" > "${WRK}/dbg-names.txt"
  printf '%s\n' "${times[@]}" > "${WRK}/dbg-times.txt"
  printf '%s\n' "${channels[@]}" > "${WRK}/dbg-channels.txt"
  exit 2
else
	echo "Processing ${#names[@]} records ..."
#  paste -d "\t" <(printf '%s\n' "${names[@]}") <(printf '[%s]\n' "${times[@]}") | sort > "${targetRaw}"
	for i in "${!names[@]}"; do
		name="${names[$i]}"
		time="${times[$i]}"
		channel="${channels[$i]}"
		if [[ "${name}" == *-* ]]; then
			printf '%s\t[%s]\n' "${name}" "${time}"
		else
			printf '%s - %s\t[%s]\n' "${channel}" "${name}" "${time}"
		fi
	done | sort > "${targetRaw}"
fi

# shellcheck disable=SC2002 #readability
cat "${targetRaw}"\
 | sed 's/([^)]*[vV]ideo[^)]*)//g'\
 | sed 's/[[:space:]]*\[[^\[]*video\]//gi'\
 | sed 's/[[:space:]]*\[[^\[]*release\]//gi'\
 | sed 's/[[:space:]]*\[[^\[]*Monstercat\]//gi'\
 | sed 's/[[:space:]]*(Official Audio)//g'\
 | sed 's/[[:space:]]*(lyrics)//g'\
 > "${targetClean}"

echo "Found $(wc -l "${targetRaw}" | awk '{print $1}') videos
Saved to ${targetRaw}"

echo "
Cleanup diff:"
wdiff -n "${targetRaw}" "${targetClean}" | colordiff | grep '\[-' | sed -e 's/\[-//g' -e  's/-\]//g'

echo "Remove duplicates in ${targetClean} and run

./list-util.sh
"
