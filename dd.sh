#!/bin/bash
mkdir /tmp/$$
(time sh -c "dd if=/dev/zero of=/tmp/$$/source oflag=direct bs=1M count=1000 && sync") 2>&1 | grep "real"
for SKIP in $(seq 0 1000); do
	printf "%i.%i%%\r" $[${SKIP}/10] $[${SKIP}%10]
	(time sh -c "dd if=/tmp/$$/source of=/tmp/$$/target conv=notrunc oflag=direct,append bs=1M count=1 skip=${SKIP}") 2>&1 | grep "real" >> /tmp/$$/log
done
cat /tmp/$$/log | cut -f 2 | cut -d m -f 2 | cut -d s -f 1 | awk '{sum+=$1} END {print sum, "minutes"}'
rm -rf /tmp/$$
