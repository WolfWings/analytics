#!/bin/bash

# Use getopts so we can pass along a -f to the underlying sar calls.
SARFILE=""
DEBUG=0
while getopts ":f:" opt; do case $opt in
	f)
		SARFILE="-f $OPTARG"
		;;
esac; done
		
# Memory usage statistics
#   Nothing special here.
#
# Networking usage statistics
#   Note this breaks the numbers into upper/middle/lower thirds,
#   so it is able to separate out the daily ebb and flow many
#   sites encounter and also partition off the 'transition'
#   periods so they don't pollute the statistics.

LC_ALL="POSIX" sar -r -n DEV $SARFILE | egrep "^[A0-9][v0-9][e:][r0-9][a0-9][g:][e0-9][0-9:]" | grep -v "RESTART" | awk '
function stddev(item, value) {
	if (value != "") {
		stddev_base[item] += value;
		stddev_sqrt[item] += (value ** 2);
		stddev_size[item] += 1;
	} else {
		if (stddev_size[item] > 0) {
			return sqrt(stddev_sqrt[item]/stddev_size[item] - (mean(item) ** 2));
		} else {
			return log(0);
		}
	}
}

function mean(item) {
	if (stddev_size[item] > 0) {
		return (stddev_base[item]/stddev_size[item]);
	} else {
		return log(0);
	}
}

function values(item, value) {
	if (value != "") {
		if (item in values_storage) {
			values_storage[item] = (values_storage[item] SUBSEP value);
		} else {
			values_storage[item] = value;
		}
	} else {
		return values_storage[item];
	}
}

BEGIN {
	mode = "";
}

{ switch(mode) {
case "memory":
	if ($1 == "Average:") {
		mode = "";
		break;
	}
	stddev("mem_u", ($3 - ($5 + $6)) / 1048576);
	stddev("mem_b", $5 / 1048576);
	stddev("mem_c", $6 / 1048576);
	break;
case "network":
	if ($1 == "Average:") {
		mode = "";
		break;
	}
	stddev(("rx_" $2), $5);
	stddev(("tx_" $2), $6);
	values(("rx_" $2), $5);
	values(("tx_" $2), $6);
	ifaces[$2] = 1;
	break;
default:
	switch($2) {
	case "kbmemfree":
		mode = "memory";
		break;
	case "IFACE":
		mode = "network";
		break;
	}
} }

END {
	printf "Memory Stats================================================================\n";
	printf "             Average       Std.Dev.\n";
	printf "Used     %9.2fGB   %9.2fGB\n", mean("mem_u"), stddev("mem_u");
	printf "Buffer   %9.2fGB   %9.2fGB\n", mean("mem_b"), stddev("mem_b");
	printf "Cache    %9.2fGB   %9.2fGB\n", mean("mem_c"), stddev("mem_c");

	for (i in values_storage) {
		split(values(i), v, SUBSEP);
		min[i] = -log(0);
		max[i] = 0;
		for (j in v) {
			k = v[j];
			if (k < min[i]) {
				min[i] = k;
			}
			if (k > max[i]) {
				max[i] = k;
			}
		}
		upper = (max[i] + max[i] + min[i]) / 3;
		lower = (max[i] + min[i] + min[i]) / 3;
		for (j in v) {
			k = v[j];
			if (k < lower) {
				stddev(("_l_" i), k);
			} else if (k <=upper) {
				stddev(("_m_" i), k);
			} else {
				stddev(("_u_" i), k);
			}
		}
	}
	printf "Network Stats===============================================================\n";
	printf "                          R                        T\n";
	printf "    Device       Average     Std.Dev.     Average     Std.Dev    Summed Peak\n";
	for (i in ifaces) {
		if ((stddev_base[("rx_" i)] >= (NR / 100)) ||
		    (stddev_base[("tx_" i)] >= (NR / 100))) {
			printf "%6s Total   %8.2f    %8.2f     %8.2f    %8.2f   %5.2fMBit/sec\n", i, mean(("rx_" i)), stddev(("rx_" i)), mean(("tx_" i)), stddev(("tx_" i)), (max[("tx_" i)] + max[("rx_" i)]) / 128;
			if ((stddev_size[("_l_rx_" i)] > 0) ||
			    (stddev_size[("_l_tx_" i)] > 0)) {
				printf "%6s Lower   %8.2f    %8.2f     %8.2f    %8.2f\n", i, mean(("_l_rx_" i)), stddev(("_l_rx_" i)), mean(("_l_tx_" i)), stddev(("_l_tx_" i));
			}
			if ((stddev_size[("_m_rx_" i)] > 0) ||
			    (stddev_size[("_m_tx_" i)] > 0)) {
				printf "%6s Midd.   %8.2f    %8.2f     %8.2f    %8.2f\n", i, mean(("_m_rx_" i)), stddev(("_m_rx_" i)), mean(("_m_tx_" i)), stddev(("_m_tx_" i));
			}
			if ((stddev_size[("_u_rx_" i)] > 0) ||
			    (stddev_size[("_u_tx_" i)] > 0)) {
				printf "%6s Upper   %8.2f    %8.2f     %8.2f    %8.2f\n", i, mean(("_u_rx_" i)), stddev(("_u_rx_" i)), mean(("_u_tx_" i)), stddev(("_u_tx_" i));
			}
		}
	}
}'
