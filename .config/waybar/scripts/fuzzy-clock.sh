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

if   [ $min -le 1 ];  then fuzzy="${current^}O'Clock Exactly"
elif [ $min -le 2 ];  then fuzzy="around ${current^}"
elif [ $min -le 7 ];  then fuzzy="just past ${current^}"
elif [ $min -le 12 ]; then fuzzy="ten past ${current^} "
elif [ $min -le 17 ]; then fuzzy="quarter past ${current^}"
elif [ $min -le 22 ]; then fuzzy="twenty past ${current^}"
elif [ $min -le 27 ]; then fuzzy="nearly half past ${current^}"
elif [ $min -le 32 ]; then fuzzy="half past ${current^}"
elif [ $min -le 37 ]; then fuzzy="thirty-odd past ${current^}"
elif [ $min -le 42 ]; then fuzzy="twenty to ${next^}"
elif [ $min -le 47 ]; then fuzzy="quarter to ${next^}"
elif [ $min -le 52 ]; then fuzzy="ten to ${next^}"
elif [ $min -le 57 ]; then fuzzy="nearly ${next^}"
else                       fuzzy="around ${next^}"
fi

utc=$(date -u +%H:%M)
printf '{"text":"%s","tooltip":"%s UTC"}\n' "$fuzzy" "$utc"
