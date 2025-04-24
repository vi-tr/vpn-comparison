#!/bin/sh -e

wpath=$(dirname $(realpath $(command -v $0)))
_2="$wpath/data.json $wpath/data.json"
_16="$_2 $_2 $_2 $_2 $_2 $_2 $_2 $_2"
_128="$_16 $_16 $_16 $_16 $_16 $_16 $_16 $_16"

cat $_128 > big_data.json
