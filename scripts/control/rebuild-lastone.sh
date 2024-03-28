#!/bin/sh
psql -U augur -h localhost -p 5432 -d padres -c 'REFRESH MATERIALIZED VIEW augur_data.explorer_new_contributors with data;'
psql -U augur -h localhost -p 5432 -d padres -c 'REFRESH MATERIALIZED VIEW augur_data.explorer_entry_list with data;'
