#!/bin/bash
set -euxo pipefail
echo "Place all jpg invoices, sum with bolt_total and write to total.txt"
read
ruby bolt.rb
cd ~/Documents/invoices
fd '.*.jpe?g' -x docker run --rm -v $(pwd):/imgs dpokidov/imagemagick:7.1.1-8-bullseye {} {.}.pdf \; -x rm {}
for d in $(ls -d 20*); do zip "Expenses ${d/\//} Joao Pinheiro.zip" $d/*.pdf; done
cd -
