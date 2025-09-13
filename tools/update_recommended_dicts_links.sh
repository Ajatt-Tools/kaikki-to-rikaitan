#!/bin/bash

set -euo pipefail

readonly source_url='https://raw.githubusercontent.com/Ajatt-Tools/rikaitan/refs/heads/main/ext/data/recommended-dictionaries.json'

# $1 = tag

get_newest_tag() {
	local newest_tag=""
	newest_tag=$(git describe --tags --abbrev=0)
	newest_tag=${newest_tag%_ipa}
	newest_tag=${newest_tag%_gloss}
	echo "$newest_tag"
}

replace_download_links() {
	local tag="$1"
	local json_file=data/${source_url##*/}

	# Use jq to process the JSON and replace download links
	jq --indent 4 --arg tag "$tag" '
	  walk(
	    if type == "object" and has("downloadUrl") and (.downloadUrl | type == "string")
	    then
	      if has("name") and (.name | test("-ipa$"))
	      then
	        .downloadUrl |= (
	          sub("/kaikki-to-rikaitan/releases/latest/download/";
		      "/kaikki-to-rikaitan/releases/download/\($tag)_ipa/") |
	          sub("/kaikki-to-rikaitan/releases/download/[A-Za-z0-9._-]+/";
		      "/kaikki-to-rikaitan/releases/download/\($tag)_ipa/")
	        )
	      else
	        .downloadUrl |= (
	          sub("/kaikki-to-rikaitan/releases/latest/download/";
		      "/kaikki-to-rikaitan/releases/download/\($tag)/") |
	          sub("/kaikki-to-rikaitan/releases/download/[A-Za-z0-9._-]+/";
		      "/kaikki-to-rikaitan/releases/download/\($tag)/")
	        )
	      end
	    else
	      .
	    end
	  )
	' "$json_file" > "${json_file}_updated"

	# Rename the updated file back to the original name
	mv -- "${json_file}_updated" "$json_file"
}

main() {
	curl --output-dir data -LOs --max-time 85 -- "$source_url"
	# The newest tag can be passed as the first arg
	local -r newest_tag=${1:-$(get_newest_tag)}
	replace_download_links "$newest_tag"
}

main "$@"
