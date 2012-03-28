#!/bin/bash

echo "Begin chroot init-scipts ..."

ROOT=/etc/rcC.d

for script in $(ls $ROOT/S* 2>/dev/null); do
	$script "$@"
done

echo "End chroot init-scipts ..."
