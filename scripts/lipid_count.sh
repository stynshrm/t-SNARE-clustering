#!/bin/bash 
if [[ $1 =~ \.pdb$ ]];
then
    cut -c13-21 $1 | grep "ROH\|AM1\|GL1"  > 00a.txt
    cat 00a.txt | uniq -c | awk '{print $3"  "$1}' 

else
    cut -c6-15 $1 | grep "ROH\|AM1\|GL1"  > 00a.txt
    cat 00a.txt | uniq -c | awk '{print $2"  "$1}' 
fi
rm 00a.txt
