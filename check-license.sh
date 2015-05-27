#!/bin/sh

egrep -v "(^$|^Files .*:$|^-+$)" license.txt | while read pattern ; do find data -type f -path "data/$pattern" ; done | sort > exp.txt
find data -type f | sort > act.txt
diff -u exp.txt act.txt
