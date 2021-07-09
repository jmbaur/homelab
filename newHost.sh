#!/usr/bin/env bash

NEWDIR="hosts/${HOSTNAME}"
mkdir $NEWDIR
mv configuration.nix hardware-configuration.nix $NEWDIR
ln -s ${PWD}/${NEWDIR}/configuration.nix $PWD
