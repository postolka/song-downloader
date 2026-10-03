#!/bin/bash

# Loads files from download location to stage
# Applies various filename modifications

set -euo pipefail

# Check required tools
REQUIRED_TOOLS=(xdg-user-dir wdiff colordiff ffprobe)
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
SRC="$(xdg-user-dir DOWNLOAD)"

# Load configuration
source "${DIR}/dl-helper.env"

mapfile -t files < <(find "${SRC}" -maxdepth 1 -type f -name "*.mp3")
mapfile -t filesCur < <(find "${DIR}/stage/" -maxdepth 1 -type f -name "*.mp3")

sedParams=()
sedParamsE=('-r')
for re in "${reRemove[@]}"; do
  sedParams+=('-e' "s/${re}//")
done
for re in "${reFixFeat[@]}"; do
  sedParamsE+=('-e' "s/${re}/(feat. \2)/")
done
for fix in "${fixAnd[@]}"; do
#	echo "s/$(echo "${fix}" | sed -e 's/ & /(\\sand|,)\\s/')/${fix}/"
  sedParams+=('-e' "s/$(echo "${fix}" | sed -e 's/ & /(\\sand|,)\\s/')/${fix}/")
done

mkdir -p "${DIR}/~retry"
mkdir -p "${DIR}/stage"

for file in "${filesCur[@]}"; do
	# Use ffprobe to get the bitrate information
	fileBase="$(basename "${file}")"
	betterName="$(basename "${fileBase}" ".mp3" | sed "${sedParams[@]}" | sed "${sedParamsE[@]}").mp3"
	diff=$(wdiff <(basename "${fileBase}" ".mp3") <(basename "${betterName}" ".mp3") | colordiff | sed -e 's/\[-//g' -e  's/-\]//g' -e  's/+}//g' -e  's/{+//g')

	# Print the filename and bitrate
	if [[ "${betterName}" != "${fileBase}" ]]; then
		echo "[ RN ]	${diff}.mp3"
		mv -T "${file}" "${DIR}/stage/${betterName}"
	fi
done


for file in "${files[@]}"; do
	# Use ffprobe to get the bitrate information
	fileBase="$(basename "${file}")"
	bitrate=$(ffprobe -v error -select_streams a:0 -show_entries stream=bit_rate -of default=noprint_wrappers=1:nokey=1 "$file" 2>/dev/null)

	kbps=$((bitrate / 1000))
	betterName="$(basename "${fileBase}" ".mp3" | sed "${sedParams[@]}" | sed "${sedParamsE[@]}").mp3"
	diff=$(wdiff <(basename "${fileBase}" ".mp3") <(basename "${betterName}" ".mp3") | colordiff | sed -e 's/\[-//g' -e  's/-\]//g' -e  's/+}//g' -e  's/{+//g')

	# Print the filename and bitrate
	if [[ $kbps -ne 320 ]]; then
		echo "[ ${kbps} ]	${fileBase}  (low bitrate => retry)"
		mv -T "${file}" "${DIR}/~retry/${kbps} - ${betterName}"
	else
		echo "[ OK ]	${diff}.mp3"
		mv -T "${file}" "${DIR}/stage/${betterName}"
	fi
done
