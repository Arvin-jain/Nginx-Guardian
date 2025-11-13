#!/usr/bin/env bash

logfile="${1:-access.log}"
paths=()     # storage array

while IFS= read -r line; do
    # extract the request portion
    req=${line#*\"}
    req=${req%%\"*}

    # remove method (GET/POST/etc)
    path_and_protocol=${req#* }

    # stop before the first HTTP
    path=${path_and_protocol%% HTTP*}

    # if extraction succeeded
    if [[ -n "$path" ]]; then
        echo "SUCCESS: extracted -> $path"
        paths+=("$path")
    else
        echo "FAILED: no valid path found in line"
    fi
done < "$logfile"

echo
echo "Total successful extractions: ${#paths[@]}"

