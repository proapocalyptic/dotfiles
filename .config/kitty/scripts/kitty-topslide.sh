#!/bin/bash
kitty -1 --class kitty-topslide \
  -o background_opacity=0.15 \
  -o dynamic_background_opacity=yes \
  -e  sh -c 'kitten @ set-background-image /home/alex/Pictures/p4-drkend-etcetc2.png; exec zsh'
