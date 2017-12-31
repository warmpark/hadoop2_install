
# Basic environment variables.  Edit as necessary
# zookeeper-3.4.8.tar.gz
#http://apache.mirror.cdnetworks.com/zookeeper/zookeeper-3.4.8/zookeeper-3.4.8.tar.gz

## JDK_VERSION=1.8.0_131
JDK_VERSION=1.8.0_152
## JDK_RPM_NAME=jdk-8u131-linux-x64.rpm
JDK_RPM_NAME=jdk-8u152-linux-x64.rpm

## JDK_DOWNLOAD_URI="http://download.oracle.com/otn-pub/java/jdk/8u131-b11/d54c1d3a095b4ff2b6607d096fa80163/${JDK_RPM_NAME}"
JDK_DOWNLOAD_URI="http://download.oracle.com/otn-pub/java/jdk/8u152-b16/aa0333dd3019491ca4f6ddbe78cdb6d0/${JDK_RPM_NAME}"
## wget --no-cookies --no-check-certificate --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" "http://download.oracle.com/otn-pub/java/jdk/8u131-b11/d54c1d3a095b4ff2b6607d096fa80163/jdk-8u131-linux-x64.rpm"
## wget --no-cookies --no-check-certificate --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" "http://download.oracle.com/otn-pub/java/jdk/8u144-b01/090f390dda5b47b9b721c7dfaa008135/jdk-8u144-linux-x64.rpm"
## wget --no-cookies --no-check-certificate --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" "http://download.oracle.com/otn-pub/java/jdk/8u152-b16/aa0333dd3019491ca4f6ddbe78cdb6d0/jdk-8u152-linux-x64.rpm"


#ZOOKEEPER_VERSION=3.4.6
ZOOKEEPER_VERSION=3.4.10 
ZOOKEEPER_DOWNLOAD_URI="http://mirror.navercorp.com/apache/zookeeper/zookeeper-${ZOOKEEPER_VERSION}/zookeeper-${ZOOKEEPER_VERSION}.tar.gz"
ZOOKEEPER_HOME="/opt/zookeeper-${ZOOKEEPER_VERSION}"
ZOOKEEPER_LOG_DIR="/var/log/zookeeper"
ZOOKEEPER_PREFIX="${ZOOKEEPER_HOME}"

ZOOKEEPER_CONF_DIR="${ZOOKEEPER_HOME}/conf"
ZOOKEEPER_DATA_DIR="/var/data/zookeeper"
ZOOKEEPER_PID_DIR="/var/run/zookeeper"

DFS_NAMESERVICES=big-cluster
HA_ZOOKEEPER_QUORUM=big01:2181,big02:2181,big03:2181

HBASE_ZOOKEEPER_QUORUM=big01,big02,big03
HBASE_ZOOKEEPER_CLIENT_PORT=2181

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



#HADOOP_VERSION=2.7.4
HADOOP_VERSION=2.7.5
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
HBASE_VERSION=1.1.13
HBASE_DOWNLOAD_URI="http://apache.tt.co.kr/hbase/${HBASE_VERSION}/hbase-${HBASE_VERSION}-bin.tar.gz"
#http://mirror.apache-kr.org/hbase/1.1.13/hbase-1.1.13-bin.tar.gz
HBASE_HOME="/opt/hbase-${HBASE_VERSION}"
HBASE_LOG_DIR="/var/log/hbase"
HBASE_PREFIX="${HBASE_HOME}"
HBASE_CONF_DIR="${HBASE_HOME}/conf"
HBASE_DATA_DIR="/var/data/hbase"
HBASE_MANAGES_ZK=false
HBASE_PID_DIR=/var/run/hbase

#### HPOENIX apache-phoenix-4.13.1-HBase-1.1-bin.tar.gz 
PHOENIX_VERSION=4.13.1
PHOENIX_HBASE_VERSION=1.1
HOENIX_DOWNLOAD_URI=" http://apache.tt.co.kr/phoenix/apache-phoenix-${PHOENIX_VERSION}-HBase-${PHOENIX_HBASE_VERSION}/bin/apache-phoenix-${PHOENIX_VERSION}-HBase-${PHOENIX_HBASE_VERSION}-bin.tar.gz"
##http://apache.tt.co.kr/phoenix/apache-phoenix-4.11.0-HBase-1.1/bin/apache-phoenix-4.11.0-HBase-1.1-bin.tar.gz
PHOENIX_HOME="/opt/apache-phoenix-${PHOENIX_VERSION}-HBase-${PHOENIX_HBASE_VERSION}-bin"
PHOENIX_LOG_DIR="/var/log/phoenix"
PHOENIX_PREFIX="${PHOENIX_HOME}"
PHOENIX_CONF_DIR="${PHOENIX_HOME}/conf"
PHOENIX_DATA_DIR="/var/data/phoenix"
PHOENIX_MANAGES_ZK=false
PHOENIX_PID_DIR=/var/run/phoenix

#### KAFKA kafka_2.11-1.0.0.tgz 
KAFKA_VERSION=1.0.0
SCALA_VERSION=2.11
KAFKA_DOWNLOAD_URI="http://mirror.apache-kr.org/kafka/${KAFKA_VERSION}/kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz"
##http://mirror.apache-kr.org/kafka/1.0.0/kafka_2.11-1.0.0.tgz
KAFKA_HOME="/opt/kafka_${SCALA_VERSION}-${KAFKA_VERSION}"
KAFKA_LOG_DIR="/var/log/kafka"
KAFKA_PREFIX="${KAFKA_HOME}"
KAFKA_CONF_DIR="${KAFKA_HOME}/config"
KAFKA_DATA_DIR="/var/data/kafka"
KAFKA_MANAGES_ZK=false
KAFKA_PID_DIR=/var/run/kafka

#### STORM 
STORM_VERSION=1.1.1
STORM_DOWNLOAD_URI="http://apache.mirror.cdnetworks.com/storm/apache-storm-${STORM_VERSION}/apache-storm-${STORM_VERSION}.tar.gz"
##http://apache.mirror.cdnetworks.com/storm/apache-storm-1.1.0/apache-storm-1.1.0.tar.gz
STORM_HOME="/opt/apache-storm-${STORM_VERSION}"
STORM_LOG_DIR="/var/log/storm"
STORM_PREFIX="${STORM_HOME}"
STORM_CONF_DIR="${STORM_HOME}/conf"
STORM_DATA_DIR="/var/data/storm"
STORM_MANAGES_ZK=false
STORM_PID_DIR=/var/run/storm
# http://apache.mirror.cdnetworks.com/storm/apache-storm-1.1.0/apache-storm-1.1.0.tar.gz
# http://mirror.navercorp.com/apache/storm/apache-storm-1.1.0/apache-storm-1.1.0.tar.gz

#### NIFI 
NIFI_VERSION=1.3.0
NIFI_DOWNLOAD_URI="http://mirror.apache-kr.org/nifi/${NIFI_VERSION}/nifi-${NIFI_VERSION}-bin.tar.gz"
##http://mirror.apache-kr.org/nifi/${NIFI_VERSION}/nifi-${NIFI_VERSION}-bin.tar.gz
##http://mirror.apache-kr.org/nifi/1.3.0/nifi-1.3.0-bin.tar.gz
NIFI_HOME="/opt/nifi-${NIFI_VERSION}"
NIFI_LOG_DIR="/var/log/nifi"
NIFI_PREFIX="${NIFI_HOME}"
NIFI_CONF_DIR="${NIFI_HOME}/conf"
NIFI_DATA_DIR="/var/data/nifi"
NIFI_MANAGES_ZK=false
NIFI_PID_DIR=/var/run/nifi


#### ZEPPELIN
ZEPPELIN_VERSION=0.7.3
ZEPPELIN_DOWNLOAD_URI="http://mirror.apache-kr.org/zeppelin/zeppelin-${ZEPPELIN_VERSION}/zeppelin-${ZEPPELIN_VERSION}-bin-all.tgz"
##http://mirror.apache-kr.org/zeppelin/zeppelin-0.7.3/zeppelin-0.7.3-bin-all.tgz
ZEPPELIN_HOME="/opt/zeppelin-${ZEPPELIN_VERSION}-bin-all"
ZEPPELIN_LOG_DIR="/var/log/zeppelin"
ZEPPELIN_PREFIX="${ZEPPELIN_HOME}"
ZEPPELIN_CONF_DIR="${ZEPPELIN_HOME}/conf"
ZEPPELIN_DATA_DIR="/var/data/zeppelin"
ZEPPELIN_MANAGES_ZK=false
ZEPPELIN_PID_DIR=/var/run/zeppelin

