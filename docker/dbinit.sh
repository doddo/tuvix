#!/bin/bash
set -ex

CONF=${MOJO_CONFIG:-/opt/tuvix/tuvix.conf}
DB_FILE=$(perl -e '$f = eval do { local $/; <STDIN> }; printf "%s", (split ":", $$f{db}[0])[2]' < $CONF)

if [ ! -f $DB_FILE ]
then
    # Create the database if need be
    /opt/tuvix/script/plerdall_db.pl --config-file $CONF --deploy-schema
fi
