#! /usr/bin/env bash

# SPDX-FileCopyrightText: 2025 NONE
#
# SPDX-License-Identifier: Unlicense

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
