#!/bin/bash

ZOOKEEPER_VERSION=3.4.8
ZOOKEEPER_HOME="/opt/zookeeper-${ZOOKEEPER_VERSION}"
ZOOKEEPER_LOG_DIR="${ZOOKEEPER_HOME}/logs"
ZOOKEEPER_PREFIX="${ZOOKEEPER_HOME}"

ZOOKEEPER_CONF_DIR="${ZOOKEEPER_HOME}/conf"
ZOOKEEPER_DATA_DIR="${ZOOKEEPER_HOME}/data"

DFS_NAMESERVICES=big-cluster
HA_ZOOKEEPER_QUORUM=big01:2181,big02:2181,big03:2181

## default /var/data/hadoop/jounal/data --- 이렇게 생성되는디....  그래서 설정을 바꾼다. 
JN_EDITS_DIR=/var/data/hadoop/jounal/data 
# Journal node group for NameNodes will wite/red edits
NAMENODE_SHARED_EDITS_DIR="qjournal://big01:8485;big02:8485;big03:8485/${DFS_NAMESERVICES}-journal"


HADOOP_VERSION=2.7.2
HADOOP_HOME="/opt/hadoop-${HADOOP_VERSION}"
NN_DATA_DIR=/var/data/hadoop/hdfs/nn
DN_DATA_DIR=/var/data/hadoop/hdfs/dn
YARN_LOG_DIR=/var/log/hadoop/yarn
HADOOP_LOG_DIR=/var/log/hadoop/hdfs
HADOOP_MAPRED_LOG_DIR=/var/log/hadoop/mapred
YARN_PID_DIR=/var/run/hadoop/yarn
HADOOP_PID_DIR=/var/run/hadoop/hdfs
HADOOP_MAPRED_PID_DIR=/var/run/hadoop/mapred
HTTP_STATIC_USER=hdfs
YARN_PROXY_PORT=8081

HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop

## VM Memory management by warmpark add.
YARN_NODEMANAGER_HEAPSIZE=308




# If using jdk-8u92-linux-x64.rpm, then
# set JAVA_HOME=""
# JAVA_HOME= /usr/lib/jvm/java-1.7.0-openjdk-1.7.0.101-2.6.6.1.el7_2.x86_64/jre/
JAVA_HOME=""



echo "Stopping Hadoop 2 services..."

pdsh -w ^jn_hosts "su - hdfs -c '$HADOOP_HOME/sbin/hadoop-daemon.sh stop zkfc'"
pdsh -w ^dn_hosts "su - hdfs -c '$HADOOP_HOME/sbin/hadoop-daemon.sh  stop datanode'"
pdsh -w ^nn_host "su - hdfs -c '$HADOOP_HOME/sbin/hadoop-daemon.sh stop namenode'"
pdsh -w ^snn_host "su - hdfs -c '$HADOOP_HOME/sbin/hadoop-daemon.sh stop namenode'"
pdsh -w ^jn_hosts "su - hdfs -c '$HADOOP_HOME/sbin/hadoop-daemon.sh stop journalnode'"
pdsh -w ^zk_hosts "su - hdfs -c '$ZOOKEEPER_HOME/bin/zkServer.sh stop'"
pdsh -w ^mr_history_host "su - mapred -c '${HADOOP_HOME}/sbin/mr-jobhistory-daemon.sh  stop historyserver'"
pdsh -w ^yarn_proxy_host "su - yarn -c '${HADOOP_HOME}/sbin/yarn-daemon.sh stop proxyserver'"
pdsh -w ^nm_hosts "su - yarn -c '${HADOOP_HOME}/sbin/yarn-daemon.sh stop nodemanager'"
pdsh -w ^rm_host "su - yarn -c '${HADOOP_HOME}/sbin/yarn-daemon.sh stop resourcemanager'"


 

#pdsh -w ^dn_hosts "service hadoop-datanode stop"
#pdsh -w ^nn_host "service hadoop-namenode stop"
#pdsh -w ^snn_host "service hadoop-namenode stop"
#pdsh -w ^mr_history_host "service hadoop-historyserver stop"
#pdsh -w ^yarn_proxy_host "service hadoop-proxyserver stop"
#pdsh -w ^nm_hosts "service hadoop-nodemanager stop"
#pdsh -w ^rm_host "service hadoop-resourcemanager stop"


#1. Zookeeper 정지
# pdsh -w ^zk_hosts "service hadoop-zookeeper stop"

echo "Removing Zookeeper services from run levels..."
pdsh -w ^dn_hosts "chkconfig --del hadoop-zookeeper"

echo "Removing Zookeeper distribution tarball..."
pdsh -w ^zk_hosts "rm -r /opt/zookeeper-$ZOOKEEPER_VERSION.tar.gz"

echo "Removing Zookeeper bash environment setting..."
pdsh -w ^zk_hosts "rm -f /etc/profile.d/zookeeper.sh"



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
pdsh -w ^zk_hosts "rm /usr/bin/zk*"

echo "Removing Hadoop 2 script links..."
pdsh -w ^all_hosts "rm /usr/libexec/hadoop-config.*"
pdsh -w ^all_hosts "rm /usr/libexec/hdfs-config.*"
pdsh -w ^all_hosts "rm /usr/libexec/httpfs-config.*"
pdsh -w ^all_hosts "rm /usr/libexec/mapred-config.*"
pdsh -w ^all_hosts "rm /usr/libexec/yarn-config.*"
pdsh -w ^all_hosts "rm /usr/libexec/kms-config.*"

echo "Uninstalling JDK 1.8.0_92 RPM..."
pdsh -w ^all_hosts "rpm -ev jdk1.8.0_92"

echo "Removing directory..."
### 구조 삭제시 시작
pdsh -w ^all_hosts "rm -rf $NN_DATA_DIR"
pdsh -w ^all_hosts "rm -rf $DN_DATA_DIR"
pdsh -w ^all_hosts "rm -rf $JN_EDITS_DIR"
pdsh -w ^all_hosts "rm -rf $YARN_LOG_DIR"
pdsh -w ^all_hosts "rm -rf $HADOOP_LOG_DIR"
pdsh -w ^all_hosts "rm -rf $HADOOP_MAPRED_LOG_DIR"
pdsh -w ^all_hosts "rm -rf $YARN_PID_DIR"
pdsh -w ^all_hosts "rm -rf $HADOOP_PID_DIR"
pdsh -w ^all_hosts "rm -rf $HADOOP_MAPRED_PID_DIR"
pdsh -w ^all_hosts "rm -rf $ZOOKEEPER_LOG_DIR"
#DK Data 초기화. 
pdsh -w ^all_hosts "rm -rf $ZOOKEEPER_DATA_DIR/version*"
pdsh -w ^all_hosts "rm -rf /etc/zookeeper"

### 구조 삭제시 끝.

pdsh -w ^all_hosts "rm -rf /var/data/hadoop"
pdsh -w ^all_hosts "rm -rf /var/log/hadoop"
pdsh -w ^all_hosts "rm -rf /var/run/hadoop"
pdsh -w ^all_hosts "rm -rf /var/run/hadoop"


pdsh -w ^all_hosts "rm -rf $HADOOP_HOME"
pdsh -w ^all_hosts "rm -rf $ZOOKEEPER_HOME"



echo "Removing hdfs system account..."
pdsh -w ^all_hosts "userdel -r hdfs"

echo "Removing mapred system account..."
pdsh -w ^all_hosts "userdel -r mapred"

echo "Removing yarn system account..."
pdsh -w ^all_hosts "userdel -r yarn"

echo "Removing hadoop system group..."
pdsh -w ^all_hosts "groupdel hadoop"

