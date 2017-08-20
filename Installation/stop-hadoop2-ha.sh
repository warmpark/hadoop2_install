#!/bin/bash
# Install Hadoop 2 using pdsh/pdcp where possible.
# 
# Command can be interactive or file-based.  This script sets up
# a Hadoop 2 cluster with basic configuration.  Modify data, log, and pid
# directories as desired.  Further configure your cluster with ./conf-hadoop2.sh
# after running this installation script.
#

. $(dirname "$0")/config-hadoop2-ha.sh

pdsh -w ^all_hosts "source /etc/profile.d/java.sh"
pdsh -w ^all_hosts "source /etc/profile.d/hadoop.sh"
pdsh -w ^zk_hosts  "source /etc/profile.d/zookeeper.sh"
pdsh -w ^all_hosts "source /etc/profile.d/hbase.sh"
pdsh -w ^all_hosts "source /etc/profile.d/kafka.sh"
pdsh -w ^all_hosts "source /etc/profile.d/storm.sh"
pdsh -w ^all_hosts "source /etc/profile.d/nifi.sh"

pdsh -w ^all_hosts "source $HADOOP_CONF_DIR/hadoop-env.sh"	
pdsh -w ^all_hosts "source $HADOOP_CONF_DIR/yarn-env.sh"
pdsh -w ^all_hosts "source $HADOOP_CONF_DIR/mapred-env.sh"
pdsh -w ^all_hosts "source $HBASE_CONF_DIR/hbase-env.sh"


source /etc/profile.d/java.sh
source /etc/profile.d/hadoop.sh
source /etc/profile.d/zookeeper.sh
source /etc/profile.d/hbase.sh
source /etc/profile.d/kafka.sh
source /etc/profile.d/storm.sh
source /etc/profile.d/nifi.sh
source $HADOOP_CONF_DIR/yarn-env.sh
source $HADOOP_CONF_DIR/mapred-env.sh
source $HBASE_CONF_DIR/hbase-env.sh

## Stop kafka
pdsh -w ^all_hosts  "su - hdfs -c '${KAFKA_HOME}/bin/kafka-server-stop.sh'" 

##_PIDFILE="./nimbus.pid"
##_PID=`cat "${_PIDFILE}"` 
##echo "Storm Nimbus (pid=${_PID}) is stopping..."
## kill -15 $_PID
## rm "${_PIDFILE}"

## STORM .....
#pdsh -w ^all_hosts  "kill -9 $(jps | grep nimbus | awk '{print $1}') | rm -f ${STORM_PID_DIR}/nimbus.pid"
pdsh -w ^all_hosts  su - hdfs -c "jps | grep nimbus | grep -v grep | awk '{print $1}'| xargs kill -9 2>/dev/null"
pdsh -w ^all_hosts  su - hdfs -c "jps | grep Supervisor | grep -v grep | awk '{print $1}'| xargs kill -9 2>/dev/null"
pdsh -w ^all_hosts  su - hdfs -c "jps | grep core | grep -v grep | awk '{print $1}'| xargs kill -9 2>/dev/null"

sleep 30

pdsh -w big01,big02,big03  "su - hdfs -c '${NIFI_HOME}/bin/nifi.sh stop'"

pdsh -w ^hbase_regionservers "su - hdfs -c '$PHOENIX_HOME/bin/queryserver.py stop'"
pdsh -w ^hbase_regionservers "su - hdfs -c '$HBASE_HOME/bin/hbase-daemon.sh stop regionserver'"
pdsh -w ^nn_host "su - hdfs -c '$HBASE_HOME/bin/hbase-daemon.sh stop master'"
pdsh -w ^nn_host "su - hdfs -c '$HADOOP_HOME/sbin/hadoop-daemon.sh stop zkfc'"
pdsh -w ^snn_host "su - hdfs -c '$HADOOP_HOME/sbin/hadoop-daemon.sh stop zkfc'"
pdsh -w ^dn_hosts "su - hdfs -c '$HADOOP_HOME/sbin/hadoop-daemon.sh  stop datanode'"
pdsh -w ^snn_host "su - hdfs -c '$HADOOP_HOME/sbin/hadoop-daemon.sh stop namenode'"
pdsh -w ^nn_host "su - hdfs -c '$HADOOP_HOME/sbin/hadoop-daemon.sh stop namenode'"
pdsh -w ^jn_hosts "su - hdfs -c '$HADOOP_HOME/sbin/hadoop-daemon.sh stop journalnode'"
pdsh -w ^zk_hosts "su - hdfs -c '$ZOOKEEPER_HOME/bin/zkServer.sh stop'"
pdsh -w ^mr_history_host "su - mapred -c '${HADOOP_HOME}/sbin/mr-jobhistory-daemon.sh  stop historyserver'"
pdsh -w ^yarn_proxy_host "su - yarn -c '${HADOOP_HOME}/sbin/yarn-daemon.sh stop proxyserver'"
pdsh -w ^nm_hosts "su - yarn -c '${HADOOP_HOME}/sbin/yarn-daemon.sh stop nodemanager'"
pdsh -w ^rm_host "su - yarn -c '${HADOOP_HOME}/sbin/yarn-daemon.sh stop resourcemanager'"

