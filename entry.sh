#!/bin/bash

UPSOURCE=/opt/Upsource

setup() {
  if [ ! "$(ls -A $UPSOURCE/conf)" ]; then
    echo "No files found in conf/, copying default configuration files"
    cp -a $UPSOURCE/.conf/. $UPSOURCE/conf/
  fi
}

setup

$UPSOURCE/bin/upsource.sh $*
