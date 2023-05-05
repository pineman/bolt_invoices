#!/bin/bash
set -euxo pipefail
echo "Place all jpg invoices, sum with bolt_total and write to total.txt"
read
ruby bolt.rb
cd ..
fd jpg -x convert {} {.}.pdf \; -x rm {}
for d in $(ls -d 20*); do zip "Expenses ${d/\//} Joao Pinheiro.zip" $d/*.pdf; done
cd -
