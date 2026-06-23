#!/bin/bash

hours=(twelve one two three four five six seven eight nine ten eleven)

hour=$(date +%I)
min=$(date +%M)

hour=$((10#$hour))
min=$((10#$min))

next_hour=$(( (hour % 12) + 1 ))
prev_hour=$((hour))

current="${hours[$((hour % 12))]} "
next="${hours[$((next_hour % 12))]}  "

if   [ $min -le 1 ];  then echo "${current^}O'Clock Exactly"
elif [ $min -le 2 ];  then echo "around ${current^}"
elif [ $min -le 7 ];  then echo "just past ${current^}"
elif [ $min -le 12 ]; then echo "ten past ${current^} "
elif [ $min -le 17 ]; then echo "quarter past ${current^}"
elif [ $min -le 22 ]; then echo "twenty past ${current^}"
elif [ $min -le 27 ]; then echo "nearly half past ${current^}"
elif [ $min -le 32 ]; then echo "half past ${current^}"
elif [ $min -le 37 ]; then echo "thirty-odd past ${current^}"
elif [ $min -le 42 ]; then echo "twenty to ${next^}"
elif [ $min -le 47 ]; then echo "quarter to ${next^}"
elif [ $min -le 52 ]; then echo "ten to ${next^}"
elif [ $min -le 57 ]; then echo "nearly ${next^}"
else                       echo "around ${next^}"
fi
