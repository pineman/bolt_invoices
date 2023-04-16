#!/bin/bash
ruby bolt.rb
cd ..
fd jpg -x convert {} {.}.pdf \; -x rm {}
for d in $(ls -d 20*); do zip "Expenses ${d/\//} João Pinheiro.zip" $d/*.pdf; done
cd -
