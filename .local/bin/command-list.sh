#!/bin/bash
DIR=/home/alex/.config/command-list
HEADER=
TITLE=Comfrey

clear
morgoth(){
#boxes $HEADER -d ansi | boxes -d ansi | lolcat  
 toilet --center -f Roman --filter gay "$TITLE" | boxes -d ansi-heavy
}


blorgoththebuilderpart2(){
	paste -d "" $DIR/joiners-self-explanatory.txt   <(paste -d "" <((column -s $'\t' -t -o $'\t' $DIR/self-explanatory)| boxes --tabs 1e -d ansi))
}


horgoth(){
column -s $'\t' -t -o $'\t' $DIR/aliai.tsv | boxes -d ansi
}





blorgoth(){
	blorgoththebuilderpart2
#	echo "           ││"
	boxes -d ansi $DIR/scripts.tsv 
}

ladies-and-gentlemen-the-orgoth-brothers(){
(horgoth)
(blorgoth)
}

morgoth
#ladies-and-gentlemen-the-orgoth-brothers
