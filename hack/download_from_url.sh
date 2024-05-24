#! /usr/bin/env bash

set -euxo pipefail

function download() {
    if [ -f "$2" ]; then
        return
    fi

    curl -L -o "$2" "$1"
}

function main() {
    download "$1" "$2"
}

main "$@"
