#!/bin/bash
echo 'base64 -d << "__EOF__" | bunzip2 > '$1'2'
bzip2 --best < $1 | base64 -w 0
echo
echo '__EOF__'
