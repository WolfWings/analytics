#!/bin/bash
read -r -d '' QUERY <<-'__EOF__'
SELECT
	CONCAT('\`',table_schema,'\`.\`',table_name,'\`') AS table_identifier,
	table_rows
FROM information_schema.tables
WHERE	engine='MyISAM'
AND	table_schema NOT IN (
	'mysql',
	'information_schema',
	'performance_schema'
)
ORDER BY table_rows DESC
__EOF__
mysql -e "${QUERY}"
