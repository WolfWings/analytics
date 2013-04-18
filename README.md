analyzers
=========

Various analysis-automation shell-scripts.

* **pastify.sh** &lt;filename&gt;

	A script to 'bundle' another file and allow transport to a server
	via simple copy-paste, using a combination of bzip2 and base64
	encoding to ensure intact transfer.

* **sar.sh** [-f filename]

	A script to "beautify" and parse the output from the _sar_ command,
	including grouping the various numerics into low/middle/high thirds
	and providing standard deviations (using the sum-of-squares method)
	to make it easier to tell what's actually going on.

* **mysql.sh**

	A script to dump a list of MyISAM tables remaining on a database,
	ordered by most rows to least to allow for easy filtering (via awk)
	then use to convert them largest-to-smallest to InnoDB if needed.

	Note that it does proper 'backtick escape' the names, so even
	tables and databases w/ spaces or other 'odd' characters work fine.

* **nova-setup.sh**

	A script to simplify setting up the environmental variables for
	the nova-client python CLI interface, geared towards copying values
	out of the CloudControl view by matching names to that.

* **https-ciphers.sh**

	A short script to pull the complete list of SSL ciphers a remote
	server supports. Limited to any ciphers the local machine it is
	run on supports.
