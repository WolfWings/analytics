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
function is_tier_item(item) {
}

function values(item, value) {
	if (item ~ /^_[lmu]_/) {
		return;
	}
	if (value != "") {
		if (item in values_storage) {
			values_storage[item] = (values_storage[item] SUBSEP value);
		} else {
			values_storage[item] = value;
		}
	} else if (item != "") {
		return values_storage[item];
	} else {
		return;
	}
}

# Calculates the standard-deviation values.
function stddev(item, value) {
	if (value != "") {
		stddev_base[item] += value;
		stddev_sqrt[item] += (value ** 2);
		stddev_size[item] += 1;
		values(item, value);
	} else {
		if (stddev_size[item] > 0) {
			return sqrt(stddev_sqrt[item]/stddev_size[item] - (mean(item) ** 2));
		} else {
			return log(0);
		}
	}
}

# This divides an item in values_storage into thirds,
# recalculating stddev for the upper, middle, and the
# lower third tiers using prefixes of _u_, _m_, & _l_
# which are also checked to avoid runaway memory use.
#
# The algo. is trivial and brute-force:
#   1) Scan all values once to find min/max.
#   2) Calculate breakpoints at the thirds.
#   3) Scan again to bin values appropriately.
function values_tiers_calculate(item) {
	if (item ~ /^_[lmu]_/) {
		return;
	}
	split(values(item), v, SUBSEP);
	min[item] = -log(0);
	max[item] = 0;
	for (j in v) {
		k = v[j];
		if (k < min[item]) {
			min[item] = k;
		}
		if (k > max[item]) {
			max[item] = k;
		}
	}
	upper = (max[item] + max[item] + min[item]) / 3;
	lower = (max[item] + min[item] + min[item]) / 3;
	for (j in v) {
		k = v[j];
		if (k < lower) {
			stddev(("_l_" item), k);
		} else if (k <=upper) {
			stddev(("_m_" item), k);
		} else {
			stddev(("_u_" item), k);
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

function output_network_range(item,   mean, range) {
	mean = mean(item);
	range = stddev(item);
	if ((mean > log(0)) && (mean < -log(0))) {
		printf "%8.2f      ", mean;
	} else {
		printf "        .       ";
	}
	if ((range > log(0)) && (range < -log(0))) {
		printf "%8.2f   ", range;
	} else {
		printf "        .     ";
	}
}

function output_network_tier(class, title, device) {
	if ((stddev_size[(class "rx_" device)] > 0) ||
	    (stddev_size[(class "tx_" device)] > 0)) {
		printf "%6s %5s   ", i, title;
		output_network_range((class "rx_" device));
		output_network_range((class "tx_" device));
		printf "\n";
	}
}

BEGIN {
	mode = "";
}

(mode == "memory") {
	if ($1 == "Average:") {
		mode = "";
	} else {
		stddev("mem_u", ($3 - ($5 + $6)) / 1048576);
		stddev("mem_b", $5 / 1048576);
		stddev("mem_c", $6 / 1048576);
	}
}

(mode == "network") {
	if ($1 == "Average:") {
		mode = "";
	} else {
		stddev(("rx_" $2), $5);
		stddev(("tx_" $2), $6);
		ifaces[$2] = 1;
	}
}

(mode == "") {
	if ($2 == "kbmemfree") {
		mode = "memory";
	} else if ($2 == "IFACE") {
		mode = "network";
	}
}

END {
	printf "Memory Stats================================================================\n";
	printf "             Average    Plus/Minus\n";
	printf "Used     %9.2fGB   %9.2fGB\n", mean("mem_u"), stddev("mem_u");
	printf "Buffer   %9.2fGB   %9.2fGB\n", mean("mem_b"), stddev("mem_b");
	printf "Cache    %9.2fGB   %9.2fGB\n", mean("mem_c"), stddev("mem_c");

	for (i in values_storage) {
		values_tiers_calculate(i);
	}

	printf "Network Stats===============================================================\n";
	printf "                        Rx                       Tx\n";
	printf "    Device      Average    Plus/Minus    Average    Plus/Minus       Peak Tx\n";
	for (i in ifaces) {
		if ((stddev_base[("rx_" i)] >= (NR / 100)) ||
		    (stddev_base[("tx_" i)] >= (NR / 100))) {
			printf "%6s Total   ", i;
			output_network_range(("rx_" i));
			output_network_range(("tx_" i));
			printf "%7.2fMbps\n", max[("tx_" i)] / 1024;

			output_network_tier("_l_", "Lower", i);
			output_network_tier("_m_", "Midd.", i);
			output_network_tier("_u_", "Upper", i);
		}
	}
}'
