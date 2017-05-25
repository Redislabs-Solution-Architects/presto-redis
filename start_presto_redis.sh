#!/bin/bash

if  [ $# -lt 4 ]; then
	echo "Required parameters: <remote hosts user name> <private key file> <number of workers> <list of hosts>"
	exit -1
fi

USER=$1
KEYFILE=$2
WORKERS=$3
shift
shift
shift
HOSTS=$@
COORDINATOR=${HOSTS%% *}
PRESTO_INSTALL_URL=https://repo1.maven.org/maven2/com/facebook/presto/presto-server/0.177/presto-server-0.177.tar.gz
INSTALL_FILE=${PRESTO_INSTALL_URL##*//*/}
INSTALL_DIR=${INSTALL_FILE%.*.*}
DATA_DIR=/var/presto/data
for h in $HOSTS
do
	SSH="ssh -i $KEYFILE $USER@$h"
	for i in $(eval echo "{1..$WORKERS}")
	do
		WORKER_INSTALL_DIR=${INSTALL_DIR}_${i}
		echo Starting worker $h $i ...
		$SSH $WORKER_INSTALL_DIR/bin/launcher start
	done
done

echo Starting coordinator ...
$SSH $INSTALL_DIR/bin/launcher start

