#!/bin/sh
BNAME=$1
TAR=tar
$TAR c --exclude=.svn -C actions . |  $TAR x -C "$BNAME"/root