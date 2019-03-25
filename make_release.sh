#!/bin/bash

release=/tmp/nelida.tar.gz

pushd $(dirname $0) > /dev/null
path=$(pwd -P)
popd > /dev/null

tar cvz --transform='s/./nelida/' ./nelida.sh ./analogy/{appa,ilar,knowledge,search,segmentation,toolbox}.lua ./analogy/ilar.sh  > /tmp/nelida.tar.gz
echo "Release built in $release"

