#!/bin/bash

if  [ $# -lt 3 ]; then
	echo "Required parameters: <remote hosts user name> <private key file> <list of hosts>"
	exit -1
fi

USER=$1
KEYFILE=$2
shift
shift
HOSTS=$@
COORDINATOR=${HOSTS%% *}
PRESTO_INSTALL_URL=https://repo1.maven.org/maven2/com/facebook/presto/presto-server/0.177/presto-server-0.177.tar.gz
INSTALL_FILE=${PRESTO_INSTALL_URL##*//*/}
INSTALL_DIR=${INSTALL_FILE%.*.*}
for h in $HOSTS
do
	SSH="ssh -i $KEYFILE $USER@$h"
	for d in `$SSH ls -d ${INSTALL_DIR}*`
        do
                $SSH test -d $d
                if [ $? -eq 0 ]; then
			echo "Stopping $h $d ..."
                        $SSH ${d}/bin/launcher stop
                fi
        done
done


