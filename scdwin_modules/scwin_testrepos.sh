#!/bin/bash
# test repos for scduply
cd ~/.scduply
find -name conf* | while read str;do 
	source $str
	echo $str $TARGET
	duplicity full $str $TARGET
done