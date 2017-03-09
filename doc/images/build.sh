#!/usr/bin/env nix-shell
#!nix-shell -i bash -p graphviz

for i in ideal problem statefulset; do
  dot -Tpng < $i.dot > $i.png
done
