#!/bin/bash

echo TRIGGERY

WIN_ID=$(kitten @ launch --type=window zsh)
sleep 3
kitten @ send-text --match id:$WIN_ID "keoap" &


#/home/alex/.local/bin/access-menu
