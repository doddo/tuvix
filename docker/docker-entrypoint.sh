#!/bin/bash
set -ex

if [ "$1" = '/opt/tuvix/perl5/bin/hypnotoad' ]; 
then
	if [ ! -f  $(perl -e 'printf "%s", (split ":", @{%{eval qx|cat /opt/tuvix/tuvix.conf|}{db}}[0] )[2]') ]; 
	then
		# Create the database if need be
	        /opt/tuvix/script/plerdall_db.pl --deploy-schema
    	fi
fi

exec "$@"
