#!/bin/bash

if [[ ! -f $1 ]]; then
  echo file '$1' not found
  exit 1
fi

function main() {
  local sha=$(sha256sum $1 | awk '{print $1;}')
  echo $sha
}

main $1