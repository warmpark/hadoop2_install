#!/bin/bash
# Install Hadoop 2 using pdsh/pdcp where possible.
# 
# Command can be interactive or file-based.  This script sets up
# a Hadoop 2 cluster with basic configuration.  Modify data, log, and pid
# directories as desired.  Further configure your cluster with ./conf-hadoop2.sh
# after running this installation script.
#

# Basic environment variables.  Edit as necessary
# zookeeper-3.4.8.tar.gz
#http://apache.mirror.cdnetworks.com/zookeeper/zookeeper-3.4.8/zookeeper-3.4.8.tar.gz

JDK_VERSION=1.8.0_131
JDK_RPM_NAME=jdk-8u131-linux-x64.rpm
JDK_DOWNLOAD_URI="http://download.oracle.com/otn-pub/java/jdk/8u131-b11/d54c1d3a095b4ff2b6607d096fa80163/${JDK_RPM_NAME}"
## wget --no-cookies --no-check-certificate --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" "http://download.oracle.com/otn-pub/java/jdk/8u131-b11/d54c1d3a095b4ff2b6607d096fa80163/jdk-8u131-linux-x64.rpm"


#ZOOKEEPER_VERSION=3.4.9
ZOOKEEPER_VERSION=3.4.6 
ZOOKEEPER_DOWNLOAD_URI="http://mirror.navercorp.com/apache/zookeeper/zookeeper-${ZOOKEEPER_VERSION}/zookeeper-${ZOOKEEPER_VERSION}.tar.gz"
ZOOKEEPER_HOME="/opt/zookeeper-${ZOOKEEPER_VERSION}"
ZOOKEEPER_LOG_DIR="/var/log/zookeeper"
ZOOKEEPER_PREFIX="${ZOOKEEPER_HOME}"

ZOOKEEPER_CONF_DIR="${ZOOKEEPER_HOME}/conf"
ZOOKEEPER_DATA_DIR="/var/data/zookeeper"

DFS_NAMESERVICES=big-cluster
HA_ZOOKEEPER_QUORUM=big01:2181,big02:2181,big03:2181

## default /var/data/hadoop/jounal/data --- 이렇게 생성되는디....  그래서 설정을 바꾼다. 
## HBase는 클라이언트에게 ZK 접근을 허락하고, Hadop은 클라이언트에게 ZK접근을 허락하지 않는다. 
# 따라서 크러스터 밖에서 원격으로 Hadoop을 사용하려면, 관련 설정정보 (XML)이 클라이언트 쪽에 배포되어야 한다. 
# 이런 이슈는 보안의 이슈과 관련되며, ZK에 대한 접근권한 관리를 한든지, 클러스터 노드들에 대한 Proxy를 구성하는지 등에 대한 안이 있어야 한다. 
# 금융권에서는 이러한 이슈가 더욱 중요한다. 

## default /var/data/hadoop/jounal/data --- 이렇게 생성되는디....  그래서 설정을 바꾼다. 
JN_EDITS_DIR=${HADOOP_DATA_DIR}/jounal

# Journal node group for NameNodes will wite/red edits
NAMENODE_SHARED_EDITS_DIR="qjournal://big01:8485;big02:8485;big03:8485/${DFS_NAMESERVICES}-journal"


#   HADOOP_CONF_DIR  Alternate conf dir. Default is ${HADOOP_PREFIX}/conf.
#   HADOOP_LOG_DIR   Where log files are stored.  PWD by default.
#   --HADOOP_MASTER    host:path where hadoop code should be rsync'd from
#   HADOOP_PID_DIR   The pid files are stored. /tmp by default.
#   --HADOOP_IDENT_STRING   A string representing this instance of hadoop. $USER by default
#   --HADOOP_NICENESS The scheduling priority for daemons. Defaults to 0.

#   YARN_CONF_DIR  Alternate conf dir. Default is ${HADOOP_YARN_HOME}/conf.
#   YARN_LOG_DIR   Where log files are stored.  PWD by default.
#   --YARN_MASTER    host:path where hadoop code should be rsync'd from
#   YARN_PID_DIR   The pid files are stored. /tmp by default.
#   --YARN_IDENT_STRING   A string representing this instance of hadoop. $USER by default
#   --YARN_NICENESS The scheduling priority for daemons. Defaults to 0.

#   HADOOP_JHS_LOGGER  Hadoop JobSummary logger.
#   HADOOP_CONF_DIR  Alternate conf dir. Default is ${HADOOP_MAPRED_HOME}/conf.
#   HADOOP_MAPRED_PID_DIR   The pid files are stored. /tmp by default.
#   --HADOOP_MAPRED_NICENESS The scheduling priority for daemons. Defaults to 0.



#HADOOP_VERSION=2.7.2
HADOOP_VERSION=2.7.3
HADOOP_DATA_DIR=/var/data/hadoop
HADOOP_DOWNLOAD_URI="http://apache.tt.co.kr/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz"
HADOOP_HOME="/opt/hadoop-${HADOOP_VERSION}"
NN_DATA_DIR=${HADOOP_DATA_DIR}/hdfs/nn
DN_DATA_DIR=${HADOOP_DATA_DIR}/hdfs/dn
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



#### HBASE 
#HBASE_VERSION=1.2.6
HBASE_VERSION=1.1.11
HBASE_DOWNLOAD_URI="http://apache.tt.co.kr/hbase/${HBASE_VERSION}/hbase-${HBASE_VERSION}-bin.tar.gz"
##http://apache.mirror.cdnetworks.com/hbase/1.2.6/hbase-1.2.6-bin.tar.gz
HBASE_HOME="/opt/hbase-${HBASE_VERSION}"
HBASE_LOG_DIR="/var/log/hbase"
HBASE_PREFIX="${HBASE_HOME}"
HBASE_CONF_DIR="${HBASE_HOME}/conf"
HBASE_DATA_DIR="/var/data/hbase"
HBASE_MANAGES_ZK=false
HBASE_PID_DIR=/var/run/hbase

#### KAFKA 
export KAFKA_VERSION=0.10.1.1
export SCALA_VERSION=2.10
KAFKA_DOWNLOAD_URI="http://mirror.apache-kr.org/kafka/${KAFKA_VERSION}/kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz"
##http://mirror.apache-kr.org/kafka/0.10.1.1/kafka_2.10-0.10.1.1.tgz
KAFKA_HOME="/opt/kafka_${SCALA_VERSION}-${KAFKA_VERSION}"
KAFKA_LOG_DIR="/var/log/kafka"
KAFKA_PREFIX="${KAFKA_HOME}"
KAFKA_CONF_DIR="${KAFKA_HOME}/conf"
KAFKA_DATA_DIR="/var/data/kafka"
KAFKA_MANAGES_ZK=false
KAFKA_PID_DIR=/var/run/kafka

#### STORM 
export STORM_VERSION=1.1.0
STORM_DOWNLOAD_URI="http://apache.mirror.cdnetworks.com/storm/apache-storm-${STORM_VERSION}/apache-storm-${STORM_VERSION}.tar.gz"
##http://apache.mirror.cdnetworks.com/storm/apache-storm-1.1.0/apache-storm-1.1.0.tar.gz
STORM_HOME="/opt/apache-storm-${STORM_VERSION}"
STORM_LOG_DIR="/var/log/storm"
STORM_PREFIX="${STORM_HOME}"
STORM_CONF_DIR="${STORM_HOME}/conf"
STORM_DATA_DIR="/var/data/strom"
STORM_MANAGES_ZK=false
STORM_PID_DIR=/var/run/storm
# http://apache.mirror.cdnetworks.com/storm/apache-storm-1.1.0/apache-storm-1.1.0.tar.gz
# http://mirror.navercorp.com/apache/storm/apache-storm-1.1.0/apache-storm-1.1.0.tar.gz

#### NIFI 
export NIFI_VERSION=1.3.0
export NIFI_DOWNLOAD_URI="http://mirror.apache-kr.org/nifi/${NIFI_VERSION}/nifi-${NIFI_VERSION}-bin.tar.gz"
##http://mirror.apache-kr.org/nifi/${NIFI_VERSION}/nifi-${NIFI_VERSION}-bin.tar.gz
##http://mirror.apache-kr.org/nifi/1.3.0/nifi-1.3.0-bin.tar.gz
NIFI_HOME="/opt/nifi-${NIFI_VERSION}"
NIFI_LOG_DIR="/var/log/nifi"
NIFI_PREFIX="${NIFI_HOME}"
NIFI_CONF_DIR="${NIFI_HOME}/conf"
NIFI_DATA_DIR="/var/data/nifi"
NIFI_MANAGES_ZK=false
NIFI_PID_DIR=/var/run/nifi



# If using local OpenJDK, it must be installed on all nodes.
# If using ${JDK_RPM_NAME}, then
# set JAVA_HOME="" and place ${JDK_RPM_NAME} in this directory
#JAVA_HOME=/usr/lib/jvm/java-1.6.0-openjdk-1.6.0.0.x86_64/
#JAVA_HOME=/usr/lib/jvm/java-1.7.0-openjdk-1.7.0.101-2.6.6.1.el7_2.x86_64/jre/
JAVA_HOME=""
source ./hadoop-xml-conf.sh
CMD_OPTIONS=$(getopt -n "$0"  -o hif --long "help,interactive,file"  -- "$@")

pdsh -w ^all_hosts "source /etc/profile.d/java.sh"
pdsh -w ^all_hosts "source /etc/profile.d/hadoop.sh"
pdsh -w ^zk_hosts  "source /etc/profile.d/zookeeper.sh"
pdsh -w ^all_hosts "source /etc/profile.d/hbase.sh"

pdsh -w ^all_hosts "source $HADOOP_CONF_DIR/hadoop-env.sh"	
pdsh -w ^all_hosts "source $HADOOP_CONF_DIR/yarn-env.sh"
pdsh -w ^all_hosts "source $HADOOP_CONF_DIR/mapred-env.sh"
pdsh -w ^all_hosts "source $HBASE_CONF_DIR/hbase-env.sh"



echo "Stopping Hadoop 2 services..."
#pdsh -w ^nn_host "su - hdfs -c '$HBASE_HOME/bin/stop-hbase.sh'"
pdsh -w ^nn_host "su - hdfs -c '$HBASE_HOME/bin/hbase-daemon.sh stop master'"
pdsh -w ^hbase_regionservers "su - hdfs -c '$HBASE_HOME/bin/hbase-daemon.sh stop regionserver'"
    
 
pdsh -w ^nn_host "su - hdfs -c '$HADOOP_HOME/sbin/hadoop-daemon.sh stop zkfc'"
pdsh -w ^snn_host "su - hdfs -c '$HADOOP_HOME/sbin/hadoop-daemon.sh stop zkfc'"
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


echo "Removing hbase distribution tarball..."
pdsh -w ^all_hosts "rm -r /opt/hbase-$HBASE_VERSION-bin.tar.gz"
echo "Removing Zookeeper distribution tarball..."
pdsh -w ^zk_hosts "rm -r /opt/zookeeper-$ZOOKEEPER_VERSION.tar.gz"
echo "Removing Hadoop 2 distribution tarball..."
pdsh -w ^all_hosts "rm -r /opt/hadoop-$HADOOP_VERSION.tar.gz"
echo "Removing JDK distribution RPM file ..."
pdsh -w ^all_hosts "rm -r /opt/$JDK_RPM_NAME"



echo "Removing hbase bash environment setting..."
pdsh -w ^all_hosts "rm -f /etc/profile.d/hbase.sh"



echo "Removing Zookeeper bash environment setting..."
pdsh -w ^zk_hosts "rm -f /etc/profile.d/zookeeper.sh"


# JAVA_HOME = "" 이면 자바삭제.
JAVA_HOME=""

echo "Removing Hadoop 2 startup scripts..."
pdsh -w ^all_hosts "rm -f /etc/init.d/hadoop-*"


#JDK삭제 하지 않기 위해 주석 처리함 삭제시 주석 해제
 if [ -z "$JAVA_HOME" ]; then
  echo "Removing JDK ${JDK_VERSION} distribution..."
  pdsh -w ^all_hosts "rm -f /opt/jdk*"

  echo "Removing JDK ${JDK_VERSION} artifacts..."
  pdsh -w ^all_hosts "rm -f sun-java*"
  pdsh -w ^all_hosts "rm -f jdk*"
fi
#JDK삭제 하지 않기 위해 주석 처리함 삭제시 주석 해제

echo "Removing Hadoop 2 bash environment setting..."
pdsh -w ^all_hosts "rm -f /etc/profile.d/hadoop.sh"

echo "Removing Java bash environment setting..."
pdsh -w ^all_hosts "rm -f /etc/profile.d/java.sh"


echo "Removing /etc/hadoop, zookeeper, hbase link..."
pdsh -w ^all_hosts "rm /etc/hadoop"
pdsh -w ^all_hosts "rm /etc/zookeeper"
pdsh -w ^all_hosts "rm /etc/hbase"

echo "Removing Hadoop 2 command links..."
pdsh -w ^all_hosts "rm /usr/bin/container-executor"
pdsh -w ^all_hosts "rm /usr/bin/hadoop*"
pdsh -w ^all_hosts "rm /usr/bin/hdfs*"
pdsh -w ^all_hosts "rm /usr/bin/mapred*"
pdsh -w ^all_hosts "rm /usr/bin/rcc*"
pdsh -w ^all_hosts "rm /usr/bin/test-container-executor"
pdsh -w ^all_hosts "rm /usr/bin/yarn*"
pdsh -w ^zk_hosts "rm /usr/bin/zk*"
pdsh -w ^all_hosts "rm /usr/bin/*hbase*"

echo "Removing Hadoop 2 script links..."
pdsh -w ^all_hosts "rm /usr/libexec/hadoop-config.*"
pdsh -w ^all_hosts "rm /usr/libexec/hdfs-config.*"
pdsh -w ^all_hosts "rm /usr/libexec/httpfs-config.*"
pdsh -w ^all_hosts "rm /usr/libexec/mapred-config.*"
pdsh -w ^all_hosts "rm /usr/libexec/yarn-config.*"
pdsh -w ^all_hosts "rm /usr/libexec/kms-config.*"

#JDK rpm 삭제 하지 않기 위해 주석 처리함 삭제시 주석 해제
echo "Uninstalling JDK ${JDK_VERSION} RPM..."
pdsh -w ^all_hosts "rpm -ev jdk${JDK_VERSION}"
#JDK rpm 삭제 하지 않기 위해 주석 처리함 삭제시 주석 해제


echo "Removing directory..."
pdsh -w ^all_hosts "rm -rf $NN_DATA_DIR"
pdsh -w ^all_hosts "rm -rf $DN_DATA_DIR"
pdsh -w ^all_hosts "rm -rf $JN_EDITS_DIR"
pdsh -w ^all_hosts "rm -rf $ZOOKEEPER_DATA_DIR"
pdsh -w ^all_hosts "rm -rf $HBASE_DATA_DIR"

pdsh -w ^all_hosts "rm -rf $YARN_LOG_DIR"
pdsh -w ^all_hosts "rm -rf $HADOOP_LOG_DIR"
pdsh -w ^all_hosts "rm -rf $HADOOP_MAPRED_LOG_DIR"
pdsh -w ^all_hosts "rm -rf $ZOOKEEPER_LOG_DIR"
pdsh -w ^all_hosts "rm -rf $HBASE_LOG_DIR"

pdsh -w ^all_hosts "rm -rf $YARN_PID_DIR"
pdsh -w ^all_hosts "rm -rf $HADOOP_PID_DIR"
pdsh -w ^all_hosts "rm -rf $HADOOP_MAPRED_PID_DIR"
pdsh -w ^all_hosts "rm -rf $HBASE_PID_DIR"

pdsh -w ^all_hosts "rm -rf $ZOOKEEPER_CONF_DIR"
pdsh -w ^all_hosts "rm -rf $HADOOP_CONF_DIR"
pdsh -w ^all_hosts "rm -rf $HBASE_CONF_DIR"

pdsh -w ^all_hosts "rm -rf /var/data/hadoop"
pdsh -w ^all_hosts "rm -rf /var/log/hadoop"
pdsh -w ^all_hosts "rm -rf /var/run/hadoop"


pdsh -w ^all_hosts "rm -rf $HADOOP_HOME"
pdsh -w ^all_hosts "rm -rf $ZOOKEEPER_HOME"
pdsh -w ^all_hosts "rm -rf $HBASE_HOME"



echo "Removing hbase system account..."
pdsh -w ^all_hosts "userdel -rf hbase"

echo "Removing hdfs system account..."
pdsh -w ^all_hosts "userdel -rf hdfs"

echo "Removing mapred system account..."
pdsh -w ^all_hosts "userdel -rf mapred"

echo "Removing yarn system account..."
pdsh -w ^all_hosts "userdel -rf yarn"

echo "Removing hadoop system group..."
pdsh -w ^all_hosts "groupdel hadoop"

