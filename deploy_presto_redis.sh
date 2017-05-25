#!/bin/bash

if  [ $# -lt 5 ]; then
	echo "Required parameters: <remote hosts user name> <private key file> <Redis connection> <number of workers> <list of hosts>"
	exit -1
fi

USER=$1
KEYFILE=$2
REDIS_CONN=$3
WORKERS=$4
shift
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
	echo Installing on $h ... 
	SSH="ssh -i $KEYFILE $USER@$h"
	$SSH "rm -rf $INSTALL_DIR; rm -rf ${DATA_DIR}*"
	$SSH "wget -q $PRESTO_INSTALL_URL"
	$SSH "tar zxf $INSTALL_FILE"
	$SSH git clone https://github.com/Redislabs-Solution-Architects/presto-redis
	$SSH "tar xf presto-redis/presto_config.tar; mv etc $INSTALL_DIR/"
	$SSH "rm -f $INSTALL_DIR/plugin/redis/presto-redis-*.jar"
	$SSH "cp presto-redis/presto-redis.jar $INSTALL_DIR/plugin/redis/"
	$SSH "rm -rf presto-redis"
	for i in $(eval echo "{1..$WORKERS}")
	do
		WORKER_INSTALL_DIR=${INSTALL_DIR}_${i}
		$SSH rm -rf $WORKER_INSTALL_DIR
		PORT=`expr 8080 + $i`
		$SSH "cp -r $INSTALL_DIR $WORKER_INSTALL_DIR"
		#$SSH "mkdir ${DATA_DIR}${i}"
		NODE_ID=`uuidgen`
		$SSH sed -i -e "s/node.id=/node.id=$NODE_ID/g" -e "s/data$/data$i/g" $WORKER_INSTALL_DIR/etc/node.properties
		$SSH sed -i -e "s/port=8080/port=$PORT/g" -e "s/localhost/$COORDINATOR/g" $WORKER_INSTALL_DIR/etc/config.properties
		$SSH sed -i  "s/redis.nodes=/redis.nodes=$REDIS_CONN/g" $WORKER_INSTALL_DIR/etc/catalog/redis.properties
		echo Starting worker $h $i ...
		$SSH $WORKER_INSTALL_DIR/bin/launcher start
	done
	$SSH rm ${INSTALL_FILE}*
done

#$SSH "mkdir ${DATA_DIR}"
NODE_ID=`uuidgen`
SSH="ssh -i $KEYFILE $USER@COORDINATOR"
$SSH sed -i -e "s/node.id=/node.id=$NODE_ID/g" $INSTALL_DIR/etc/node.properties
$SSH cp $INSTALL_DIR/etc/config.properties.coordinator $INSTALL_DIR/etc/config.properties
$SSH sed -i  "s/redis.nodes=/redis.nodes=$REDIS_CONN/g" $INSTALL_DIR/etc/catalog/redis.properties
echo Starting coordinator ...
$SSH $INSTALL_DIR/bin/launcher start

