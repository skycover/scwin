#!/bin/bash
# test repos for scduply
cd ~/.scduply
find -name conf* | while read str;do 
	source $str
	echo $str $TARGET
	[ ! -z $TARGET ] && (
		duplicity full $str $TARGET
		unset TARGET
	)
done