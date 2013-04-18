#!/bin/bash
echo 'base64 -d -i << "__EOF__" | bunzip2 > '$1
cat $1 | bzip2 --best | base64 -w 0
echo
echo '__EOF__'
