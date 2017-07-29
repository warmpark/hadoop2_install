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
JN_EDITS_DIR=/var/data/hadoop/jounal

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
HADOOP_DOWNLOAD_URI="http://apache.tt.co.kr/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz"
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



# Take care of bad options in the command
if [ $? -ne 0 ];
then
  exit 1
fi
eval set -- "$CMD_OPTIONS"

all_hosts="all_hosts"
nn_host="nn_host"
snn_host="snn_host"
dn_hosts="dn_hosts"
rm_host="rm_host"
nm_hosts="nm_hosts"
mr_history_host="mr_history_host"
yarn_proxy_host="yarn_proxy_host"
zk_hosts="zk_hosts"

install()
{
	## HADOOP DOWNLOAD
    hdfile=./hadoop-${HADOOP_VERSION}.tar.gz
    if [ ! -e "$hdfile" ]; then
        echo "Hadoop File does not exist"
        wget ${HADOOP_DOWNLOAD_URI} 
    else 
        echo "Hadoop File exists"
    fi
    
    ## ZKOOPER DOWNLOAD
    zkfile=./zookeeper-${ZOOKEEPER_VERSION}.tar.gz
    if [ ! -e "$zkfile" ]; then
        echo "Zookeeper File does not exist"
        wget ${ZOOKEEPER_DOWNLOAD_URI}
    else 
        echo "Zookeeper File exists"
    fi


    ## HBASE DOWNLOAD
    hbasefile=./hbase-${HBASE_VERSION}-bin.tar.gz
    if [ ! -e "$hbasefile" ]; then
        echo "File does not exist"
        wget ${HBASE_DOWNLOAD_URI}
    else 
        echo "HBASE File exists"
    fi
 
    ## KAFKA DOWNLOAD
    kafkafile=./kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz
    if [ ! -e "$kafkafile" ]; then
        echo "File does not exist"
        wget ${KAFKA_DOWNLOAD_URI}
    else 
        echo "KAFKA File exists"
    fi
 
    ## STORM DOWNLOAD
    stormfile=./apache-storm-${STORM_VERSION}.tar.gz
    if [ ! -e "$stormfile" ]; then
        echo "File does not exist"
        wget ${STORM_DOWNLOAD_URI}
    else 
        echo "STORM File exists"
    fi
	
    ## NIFI DOWNLOAD
    nififile=./nifi-${NIFI_VERSION}-bin.tar.gz
    if [ ! -e "$nififile" ]; then
        echo "File does not exist"
        wget ${NIFI_DOWNLOAD_URI}
    else 
        echo "NIFI File exists"
    fi
    
    echo "Copying hadoop-"$HADOOP_VERSION".tar.gz,  zookeeper-"$ZOOKEEPER_VERSION".tar.gz, hbase-${HBASE_VERSION}-bin.tar.gz, kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz, apache-storm-${STORM_VERSION}.tar.gz, nifi-${NIFI_VERSION}-bin.tar.gz to all hosts..."
	pdcp -w ^all_hosts hadoop-"$HADOOP_VERSION".tar.gz /opt
    pdcp -w ^all_hosts zookeeper-"$ZOOKEEPER_VERSION".tar.gz /opt
    pdcp -w ^all_hosts hbase-${HBASE_VERSION}-bin.tar.gz /opt
	pdcp -w ^all_hosts kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz /opt
	pdcp -w ^all_hosts apache-storm-${STORM_VERSION}.tar.gz /opt
	pdcp -w ^all_hosts nifi-${NIFI_VERSION}-bin.tar.gz /opt
    
}

interactive()
{
	echo -n "Enter NameNode hostname: "
	read nn
	echo -n "Enter Secondary NameNode or NameNode2 hostname: "
	read snn
	echo -n "Enter ResourceManager hostname: "
	read rmgr
	echo -n "Enter Job History Server hostname: "
	read mr_hist
	echo -n "Enter YARN Proxy hostname: "
	read yarn_proxy
	echo -n "Enter DataNode hostnames (comma separated or hostlist syntax): "
	read dns
	echo -n "Enter NodeManager hostnames (comma separated or hostlist syntax): "
	read nms
    echo -n "Enter JournalNode hostnames (comma separated or hostlist syntax): "
    read jns

	echo "$nn" > "$nn_host"
	echo "$snn" > "$snn_host"
	echo "$rmgr" > "$rm_host"
	echo "$mr_hist" > "$mr_history_host"
	echo "$yarn_proxy" > "$yarn_proxy_host"
	dn_hosts_var=$(sed 's/\,/\n/g' <<< $dns)
	nm_hosts_var=$(sed 's/\,/\n/g' <<< $nms)
    zk_hosts_var=$(sed 's/\,/\n/g' <<< $jns)
	echo "$dn_hosts_var" > "$dn_hosts"
	echo "$nm_hosts_var" > "$nm_hosts"
    echo "$zk_hosts_var" > "$zk_hosts"
	echo "$(echo "$nn $snn $rmgr $mr_hist $yarn_proxy $dn_hosts_var $nm_hosts_var $zk_hosts_var" | tr ' ' '\n' | sort -u)" > "$all_hosts"
}

file()
{
	nn=$(cat nn_host)
	snn=$(cat snn_host)
	rmgr=$(cat rm_host)
	mr_hist=$(cat mr_history_host)
	yarn_proxy=$(cat yarn_proxy_host)
	dns=$(cat dn_hosts)
	nms=$(cat nm_hosts)
    jns=$(cat zk_hosts)
	
	echo "$(echo "$nn $snn $rmgr $mr_hist $dns $nms $jns" | tr ' ' '\n' | sort -u)" > "$all_hosts"
}

help()
{
cat << EOF
install-hadoop2.sh 
 
This script installs Hadoop 2 with basic data, log, and pid directories. 
 
USAGE:  install-hadoop2.sh [options]
 
OPTIONS:
   -i, --interactive      Prompt for fully qualified domain names (FQDN) of the NameNode,
                          Secondary NameNode, DataNodes, ResourceManager, NodeManagers,
                          MapReduce Job History Server, and YARN Proxy server.  Values
                          entered are stored in files in the same directory as this command. 
                          
   -f, --file             Use files with fully qualified domain names (FQDN), new-line
                          separated.  Place files in the same directory as this script. 
                          Services and file name are as follows:
                          NameNode = nn_host
                          Secondary NameNode = snn_host
                          DataNodes = dn_hosts
                          ResourceManager = rm_host
                          NodeManagers = nm_hosts
                          MapReduce Job History Server = mr_history_host
                          YARN Proxy Server = yarn_proxy_host
                          
   -h, --help             Show this message.
   
EXAMPLES: 
   Prompt for host names: 
     install-hadoop2.sh -i
     install-hadoop2.sh --interactive
   
   Use values from files in the same directory:
     install-hadoop2.sh -f
     install-hadoop2.sh --file
             
EOF
}

while true;
do
  case "$1" in

    -h|--help)
      help
      exit 0
      ;;
    -i|--interactive)
      interactive
      install
      shift
      ;;
    -f|--file)
      file
      install
      shift
      ;;
    --)
      shift
      break
      ;;
  esac
done
