#!/bin/bash


ZOOKEEPER_VERSION=3.4.8
ZOOKEEPER_HOME="/opt/zookeeper-${ZOOKEEPER_VERSION}"
ZOOKEEPER_LOG_DIR="${ZOOKEEPER_HOME}/logs"
ZOOKEEPER_PREFIX="${ZOOKEEPER_HOME}"
ZOOKEEPER_CONF_DIR="${ZOOKEEPER_HOME}/conf"
ZOOKEEPER_DATA_DIR="${ZOOKEEPER_HOME}/data"
JN_EDITS_DIR=/var/data/hadoop/journal/data


HADOOP_VERSION=2.7.2
HADOOP_HOME="/opt/hadoop-${HADOOP_VERSION}"
NN_DATA_DIR=/var/data/hadoop/hdfs/nn
SNN_DATA_DIR=/var/data/hadoop/hdfs/snn
DN_DATA_DIR=/var/data/hadoop/hdfs/dn
YARN_LOG_DIR=/var/log/hadoop/yarn
HADOOP_LOG_DIR=/var/log/hadoop/hdfs
HADOOP_MAPRED_LOG_DIR=/var/log/hadoop/mapred



#HADOOP_CONF_DIR=/etc/hadoop
HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop

## VM Memory management by warmpark add.
YARN_NODEMANAGER_HEAPSIZE=308



# If using jdk-8u92-linux-x64.rpm, then
# set JAVA_HOME=""
# JAVA_HOME= /usr/lib/jvm/java-1.7.0-openjdk-1.7.0.101-2.6.6.1.el7_2.x86_64/jre/
JAVA_HOME=""
echo "Stopping Hadoop 2 services..."
pdsh -w ^dn_hosts "service hadoop-datanode stop"
pdsh -w ^nn_host "service hadoop-namenode stop"
pdsh -w ^snn_host "service hadoop-namenode stop"
pdsh -w ^mr_history_host "service hadoop-historyserver stop"
pdsh -w ^yarn_proxy_host "service hadoop-proxyserver stop"
pdsh -w ^nm_hosts "service hadoop-nodemanager stop"
pdsh -w ^rm_host "service hadoop-resourcemanager stop"

echo "Removing Hadoop 2 services from run levels..."
pdsh -w ^dn_hosts "chkconfig --del hadoop-datanode"
pdsh -w ^nn_host "chkconfig --del hadoop-namenode"
pdsh -w ^snn_host "chkconfig --del hadoop-namenode"
pdsh -w ^mr_history_host "chkconfig --del hadoop-historyserver"
pdsh -w ^yarn_proxy_host "chkconfig --del hadoop-proxyserver"
pdsh -w ^nm_hosts "chkconfig --del hadoop-nodemanager"
pdsh -w ^rm_host "chkconfig --del hadoop-resourcemanager"

echo "Removing Hadoop 2 startup scripts..."
pdsh -w ^all_hosts "rm -f /etc/init.d/hadoop-*"

echo "Removing Hadoop 2 distribution tarball..."
pdsh -w ^all_hosts "rm -f /opt/hadoop-2*.tar.gz"
push -w ˆjn_hosts "rm -r /opt/zookeeper-$ZOOKEEPER_VERSION.tar.gz"

if [ -z "$JAVA_HOME" ]; then
  echo "Removing JDK 1.8.0_92 distribution..."
  pdsh -w ^all_hosts "rm -f /opt/jdk*"

  echo "Removing JDK 1.8.0_92 artifacts..."
  pdsh -w ^all_hosts "rm -f sun-java*"
  pdsh -w ^all_hosts "rm -f jdk*"
fi


echo "Removing Hadoop 2 bash environment setting..."
pdsh -w ^all_hosts "rm -f /etc/profile.d/hadoop.sh"

echo "Removing Java bash environment setting..."
pdsh -w ^all_hosts "rm -f /etc/profile.d/java.sh"

echo "Removing /etc/hadoop link..."
pdsh -w ^all_hosts "rm /etc/hadoop"

echo "Removing Hadoop 2 command links..."
pdsh -w ^all_hosts "rm /usr/bin/container-executor"
pdsh -w ^all_hosts "rm /usr/bin/hadoop*"
pdsh -w ^all_hosts "rm /usr/bin/hdfs*"
pdsh -w ^all_hosts "rm /usr/bin/mapred*"
pdsh -w ^all_hosts "rm /usr/bin/rcc*"
pdsh -w ^all_hosts "rm /usr/bin/test-container-executor"
pdsh -w ^all_hosts "rm /usr/bin/yarn*"
pdsh -w ˆjn_hosts "rm /usr/bin/zk*"

echo "Removing Hadoop 2 script links..."
pdsh -w ^all_hosts "rm /usr/libexec/hadoop-config.*"
pdsh -w ^all_hosts "rm /usr/libexec/hdfs-config.*"
pdsh -w ^all_hosts "rm /usr/libexec/httpfs-config.*"
pdsh -w ^all_hosts "rm /usr/libexec/mapred-config.*"
pdsh -w ^all_hosts "rm /usr/libexec/yarn-config.*"
pdsh -w ^all_hosts "rm /usr/libexec/kms-config.*"

echo "Uninstalling JDK 1.8.0_92 RPM..."
pdsh -w ^all_hosts "rpm -ev jdk1.8.0_92"

echo "Removing NameNode data directory..."
pdsh -w ^nn_host "rm -Rf $NN_DATA_DIR"

echo "Removing Secondary NameNode data directory..."
pdsh -w ^snn_host "rm -Rf $NN_DATA_DIR"

echo "Removing DataNode data directories..."
pdsh -w ^dn_hosts "rm -Rf $DN_DATA_DIR"

echo "Removing JournalNode data directories..."
pdsh -w ^jn_hosts "rm -Rf $JN_EDITS_DIR"

echo "Removing YARN log directories..."
pdsh -w ^all_hosts "rm -Rf $YARN_LOG_DIR"

echo "Removing HDFS log directories..."
pdsh -w ^all_hosts "rm -Rf $HADOOP_LOG_DIR"

echo "Removing MapReduce log directories..."
pdsh -w ^all_hosts "rm -Rf $HADOOP_MAPRED_LOG_DIR"



echo "Removing Hadoop 2 home directory..."
pdsh -w ^all_hosts "rm -Rf $HADOOP_HOME"

echo "Removing Zookeeper home directory..."
push -w ˆjn_hosts "rm -Rf $ZOOKEEPER_HOME"


echo "Removing hdfs system account..."
pdsh -w ^all_hosts "userdel -r hdfs"

echo "Removing mapred system account..."
pdsh -w ^all_hosts "userdel -r mapred"

echo "Removing yarn system account..."
pdsh -w ^all_hosts "userdel -r yarn"

echo "Removing hadoop system group..."
pdsh -w ^all_hosts "groupdel hadoop"

