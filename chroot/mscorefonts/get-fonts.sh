#!/bin/bash

set -e

FONTS='andale32.exe arial32.exe arialb32.exe comic32.exe courie32.exe 
georgi32.exe impact32.exe times32.exe trebuc32.exe verdan32.exe webdin32.exe'

URLROOTS="http://downloads.sourceforge.net/corefonts/
    http://switch.dl.sourceforge.net/sourceforge/corefonts/
    http://mesh.dl.sourceforge.net/sourceforge/corefonts/
    http://dfn.dl.sourceforge.net/sourceforge/corefonts/
    http://heanet.dl.sourceforge.net/sourceforge/corefonts/
    http://jaist.dl.sourceforge.net/sourceforge/corefonts/
    http://nchc.dl.sourceforge.net/sourceforge/corefonts/
    http://ufpr.dl.sourceforge.net/sourceforge/corefonts/
    http://internode.dl.sourceforge.net/sourceforge/corefonts/
    http://voxel.dl.sourceforge.net/sourceforge/corefonts/
    http://kent.dl.sourceforge.net/sourceforge/corefonts/
    http://internap.dl.sourceforge.net/sourceforge/corefonts/"

for font in $FONTS
do
    for website in $URLROOTS
    do
        if ! wget -c ${website}${font} ; then
            continue 1;
        fi
        break
    done
done

echo Done
