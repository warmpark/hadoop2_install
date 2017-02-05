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

DK_VERSION=1.8.0_121
JDK_RPM_NAME=jdk-8u121-linux-x64.rpm
JDK_DOWNLOAD_URI="http://download.oracle.com/otn-pub/java/jdk/8u121-b13/e9e7ea248e2c4826b92b3f075a80e441/${JDK_RPM_NAME}"


ZOOKEEPER_VERSION=3.4.9
ZOOKEEPER_DOWNLOAD_URI="http://mirror.navercorp.com/apache/zookeeper/zookeeper-${ZOOKEEPER_VERSION}/zookeeper-${ZOOKEEPER_VERSION}.tar.gz"
ZOOKEEPER_HOME="/opt/zookeeper-${ZOOKEEPER_VERSION}"
ZOOKEEPER_LOG_DIR="/var/log/zookeeper/yarn/logs"
ZOOKEEPER_PREFIX="${ZOOKEEPER_HOME}"

ZOOKEEPER_CONF_DIR="${ZOOKEEPER_HOME}/conf"
ZOOKEEPER_DATA_DIR="/var/data/zookeeper/data"

DFS_NAMESERVICES=big-cluster
HA_ZOOKEEPER_QUORUM=big01:2181,big02:2181,big03:2181

## default /var/data/hadoop/jounal/data --- 이렇게 생성되는디....  그래서 설정을 바꾼다. 
## HBase는 클라이언트에게 ZK 접근을 허락하고, Hadop은 클라이언트에게 ZK접근을 허락하지 않는다. 
# 따라서 크러스터 밖에서 원격으로 Hadoop을 사용하려면, 관련 설정정보 (XML)이 클라이언트 쪽에 배포되어야 한다. 
# 이런 이슈는 보안의 이슈과 관련되며, ZK에 대한 접근권한 관리를 한든지, 클러스터 노드들에 대한 Proxy를 구성하는지 등에 대한 안이 있어야 한다. 
# 금융권에서는 이러한 이슈가 더욱 중요한다. 

JN_EDITS_DIR=/var/data/hadoop/jounal/data 
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



# HADOOP_VERSION=2.7.2
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
# If using local OpenJDK, it must be installed on all nodes.
# If using ${JDK_RPM_NAME}, then
# set JAVA_HOME="" and place ${JDK_RPM_NAME} in this directory
#JAVA_HOME=/usr/lib/jvm/java-1.6.0-openjdk-1.6.0.0.x86_64/
#JAVA_HOME=/usr/lib/jvm/java-1.7.0-openjdk-1.7.0.101-2.6.6.1.el7_2.x86_64/jre/
JAVA_HOME=""
source ./hadoop-xml-conf.sh
CMD_OPTIONS=$(getopt -n "$0"  -o hif --long "help,interactive,file"  -- "$@")
HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop

## VM Memory management by warmpark add.
YARN_NODEMANAGER_HEAPSIZE=308



#### HBASE 
HBASE_VERSION=1.2.4
HBASE_DOWNLOAD_URI="http://apache.tt.co.kr/hbase/${HBASE_VERSION}/hbase-${HBASE_VERSION}-bin.tar.gz"
HBASE_HOME="/opt/hbase-${HBASE_VERSION}"
HBASE_LOG_DIR="/var/log/hbase"
HBASE_PREFIX="${HBASE_HOME}"
HBASE_CONF_DIR="${HBASE_HOME}/conf"
HBASE_DATA_DIR="/var/data/hbase"
HBASE_MANAGES_ZK=false
HBASE_PID_DIR=/var/run/hbase





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
        echo "File exists"
    fi
   
    
    echo "Copying Hadoop $HADOOP_VERSION to all hosts..."
	pdcp -w ^all_hosts hadoop-"$HADOOP_VERSION".tar.gz /opt
    pdcp -w ^all_hosts zookeeper-"$ZOOKEEPER_VERSION".tar.gz /opt
    pdcp -w ^all_hosts hbase-${HBASE_VERSION}-bin.tar.gz /opt
    
if [ -z "$JAVA_HOME" ]; then
	echo "Download & Copying JDK ${JDK_VERSION} to all hosts..."
    ## JDK DOWNLOAD
        
    ## ZKOOPER DOWNLOAD
    if [ ! -e "$JDK_RPM_NAME" ]; then
        echo "JDK PRM File does not exist"
        wget --no-cookies --no-check-certificate --header "Cookie:gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" ${JDK_DOWNLOAD_URI}
    else 
        echo "JDK PRM File exists"
    fi
	pdcp -w ^all_hosts ${JDK_RPM_NAME} /opt

	echo "Installing JDK ${JDK_VERSION} on all hosts..."
	pdsh -w ^all_hosts chmod a+x /opt/${JDK_RPM_NAME}
	#pdsh -w ^all_hosts /opt/${JDK_RPM_NAME} -noregister 1>&- 2>&-
	pdsh -w ^all_hosts rpm -ivh /opt/${JDK_RPM_NAME} 1>&- 2>&-
	JAVA_HOME=/usr/java/jdk${JDK_VERSION}
	echo "JAVA_HOME=$JAVA_HOME"
fi
	echo "Setting JAVA_HOME and HADOOP_HOME environment variables on all hosts..."
	
	echo "JAVA_HOME=$JAVA_HOME > /etc/profile.d/java.sh"
	pdsh -w ^all_hosts "echo export JAVA_HOME=$JAVA_HOME >> /etc/profile.d/java.sh"
    pdsh -w ^all_hosts "echo export PATH=$JAVA_HOME/bin:$PATH >> /etc/profile.d/java.sh"
	pdsh -w ^all_hosts "source /etc/profile.d/java.sh"
    

    
    
 	echo "Creating system accounts and groups on all hosts..."
	pdsh -w ^all_hosts groupadd hadoop
	pdsh -w ^all_hosts useradd -g hadoop yarn
	pdsh -w ^all_hosts useradd -g hadoop hdfs
	pdsh -w ^all_hosts useradd -g hadoop mapred
    pdsh -w ^all_hosts useradd -g hadoop hbase
    
	
    echo "Extracting Hadoop $HADOOP_VERSION distribution on all hosts..."
	pdsh -w ^all_hosts tar -zxf /opt/hadoop-"$HADOOP_VERSION".tar.gz -C /opt

    echo "Extracting Zookeeper $ZOOKEEPER_VERSION distribution on all ZK hosts..."
	pdsh -w ^zk_hosts tar -zxf /opt/zookeeper-"$ZOOKEEPER_VERSION".tar.gz -C /opt

    echo "Extracting HBASE $HBASE_VERSION distribution on all hosts..."
	pdsh -w ^all_hosts tar -zxf /opt/hbase-${HBASE_VERSION}-bin.tar.gz -C /opt



	pdsh -w ^all_hosts "echo export HADOOP_HOME=$HADOOP_HOME > /etc/profile.d/hadoop.sh"
	pdsh -w ^all_hosts "echo export HADOOP_PREFIX=$HADOOP_HOME >> /etc/profile.d/hadoop.sh"
    pdsh -w ^all_hosts "echo export HADOOP_CONF_DIR=$HADOOP_CONF_DIR >> /etc/profile.d/hadoop.sh"
	pdsh -w ^all_hosts "source /etc/profile.d/hadoop.sh"
    
	pdsh -w ^zk_hosts "echo export ZOOKEEPER_HOME=$ZOOKEEPER_HOME > /etc/profile.d/zookeeper.sh"
	pdsh -w ^zk_hosts "echo export ZOOKEEPER_PREFIX=$ZOOKEEPER_HOME >> /etc/profile.d/zookeeper.sh"
	pdsh -w ^zk_hosts "echo export ZOOKEEPER_LOG_DIR=$ZOOKEEPER_LOG_DIR >> /etc/profile.d/zookeeper.sh"
	pdsh -w ^zk_hosts "echo export ZOO_LOG_DIR=$ZOOKEEPER_LOG_DIR >> /etc/profile.d/zookeeper.sh"
	pdsh -w ^zk_hosts "source /etc/profile.d/zookeeper.sh"
    
    
    pdsh -w ^zk_hosts "echo export HBASE_HOME=$HBASE_HOME > /etc/profile.d/hbase.sh"
	pdsh -w ^zk_hosts "echo export HBASE_PREFIX=$HBASE_HOME >> /etc/profile.d/hbase.sh"
	pdsh -w ^zk_hosts "echo export HBASE_LOG_DIR=$HBASE_LOG_DIR >> /etc/profile.d/hbase.sh"
    pdsh -w ^all_hosts "echo export PATH=$HBASE_HOME/bin:$PATH >> /etc/profile.d/hbase.sh"
	pdsh -w ^zk_hosts "source /etc/profile.d/hbase.sh"
    
        
    echo "Editing Hadoop environment scripts for log directories on all hosts..."
	pdsh -w ^all_hosts echo "export HADOOP_LOG_DIR=$HADOOP_LOG_DIR >> $HADOOP_CONF_DIR/hadoop-env.sh"
	pdsh -w ^all_hosts echo "export YARN_LOG_DIR=$YARN_LOG_DIR >> $HADOOP_CONF_DIR/yarn-env.sh"
	pdsh -w ^all_hosts echo "export HADOOP_MAPRED_LOG_DIR=$HADOOP_MAPRED_LOG_DIR >> $HADOOP_CONF_DIR/mapred-env.sh"

	echo "Editing Hadoop environment scripts for pid directories on all hosts..."
	pdsh -w ^all_hosts echo "export HADOOP_PID_DIR=$HADOOP_PID_DIR >> $HADOOP_CONF_DIR/hadoop-env.sh"
	pdsh -w ^all_hosts echo "export YARN_PID_DIR=$YARN_PID_DIR >> $HADOOP_CONF_DIR/yarn-env.sh"
	pdsh -w ^all_hosts echo "export HADOOP_MAPRED_PID_DIR=$HADOOP_MAPRED_PID_DIR >> $HADOOP_CONF_DIR/mapred-env.sh"
    pdsh -w ^all_hosts echo "export HBASE_PID_DIR=$HBASE_PID_DIR >> $HBASE_CONF_DIR/hbase-env.sh"
    ### ZK  PID관리는 어떻게.....
    
  
    ## 각종 저장 장소의 기본 사용자는 hdfs... 
    pdsh -w ^all_hosts "mkdir -p /var/data/hadoop && chown -R hdfs:hadoop /var/data/hadoop"
    pdsh -w ^all_hosts "mkdir -p /var/log/hadoop && chown -R hdfs:hadoop /var/log/hadoop"
    pdsh -w ^all_hosts "mkdir -p /var/run/hadoop && chown -R hdfs:hadoop /var/run/hadoop"
    
        
	echo "Creating HDFS data directories on NameNode host, JournalNode hosts, Secondary NameNode host, and DataNode hosts..."
    #pdsh -w ^all_hosts "mkdir -p $NN_DATA_DIR && chown hdfs:hadoop $NN_DATA_DIR"
    pdsh -w ^all_hosts "mkdir -p $NN_DATA_DIR && chown -R hdfs:hadoop $NN_DATA_DIR"
	pdsh -w ^all_hosts "mkdir -p $DN_DATA_DIR && chown -R hdfs:hadoop $DN_DATA_DIR"
    pdsh -w ^all_hosts "mkdir -p $JN_EDITS_DIR && chown -R hdfs:hadoop $JN_EDITS_DIR"
    pdsh -w ^all_hosts "mkdir -p $ZOOKEEPER_DATA_DIR && chown -R hdfs:hadoop $ZOOKEEPER_DATA_DIR"
    ## HBASE
    pdsh -w ^all_hosts "mkdir -p ${HBASE_DATA_DIR} && chown -R hbase:hadoop ${HBASE_DATA_DIR}"
        

	echo "Creating log directories on all hosts..."
	pdsh -w ^all_hosts "mkdir -p $YARN_LOG_DIR && chown -R yarn:hadoop $YARN_LOG_DIR"
	pdsh -w ^all_hosts "mkdir -p $HADOOP_LOG_DIR && chown -R hdfs:hadoop $HADOOP_LOG_DIR"
	pdsh -w ^all_hosts "mkdir -p $HADOOP_MAPRED_LOG_DIR && chown -R mapred:hadoop $HADOOP_MAPRED_LOG_DIR"
    pdsh -w ^all_hosts "mkdir -p $ZOOKEEPER_LOG_DIR && chown -R hdfs:hadoop $ZOOKEEPER_LOG_DIR"
    ## HBASE
    pdsh -w ^all_hosts "mkdir -p ${HBASE_LOG_DIR} && chown -R hbase:hadoop ${HBASE_LOG_DIR}"
    

	echo "Creating pid directories on all hosts..."
	pdsh -w ^all_hosts "mkdir -p $YARN_PID_DIR && chown -R yarn:hadoop $YARN_PID_DIR"
	pdsh -w ^all_hosts "mkdir -p $HADOOP_PID_DIR && chown -R hdfs:hadoop $HADOOP_PID_DIR"
	pdsh -w ^all_hosts "mkdir -p $HADOOP_MAPRED_PID_DIR && chown -R mapred:hadoop $HADOOP_MAPRED_PID_DIR"
    pdsh -w ^all_hosts "mkdir -p $HBASE_PID_DIR && chown -R hbase:hadoop $HBASE_PID_DIR"
    ##TODO JK PID는 어떻게 ? 어디에 ? 구글링해봐야...
    

    


	if [ -n "$YARN_NODEMANAGER_HEAPSIZE" ]
	then 
		echo "for VM Memory Management  by warmpark   Editing Hadoop yarn-env.sh environment for YARN_NODEMANAGER_HEAPSIZE on all hosts..."
		pdsh -w ^all_hosts echo "export YARN_NODEMANAGER_HEAPSIZE=$YARN_NODEMANAGER_HEAPSIZE >> $HADOOP_CONF_DIR/yarn-env.sh"
	fi
   
   
   	echo "HBASE hbase-env.sh"
    pdsh -w ^all_hosts echo "export HBASE_MANAGES_ZK=$HBASE_MANAGES_ZK >> ${HBASE_CONF_DIR}/hbase-env.sh"
    
    
    echo "Editing zookeeper conf zoo.cfg - 나중에 보완할 필요...."
    pdsh -w ^all_hosts "echo     'dataDir=$ZOOKEEPER_DATA_DIR
    dataLogDir=$ZOOKEEPER_HOME/logs
    clientPort=2181
    initLimit=5
    syncLimit=2
    server.1=big01:2888:3888
    server.2=big02:2888:3888
    server.3=big03:2888:3888' >  $ZOOKEEPER_CONF_DIR/zoo.cfg"

    
    echo "Make zookeeper id in  $ZOOKEEPER_DATA_DIR/myid - 나중에 보완할 필요...."
    pdsh -w big01 "echo 1 > $ZOOKEEPER_DATA_DIR/myid"
    pdsh -w big02 "echo 2 > $ZOOKEEPER_DATA_DIR/myid"
    pdsh -w big03 "echo 3 > $ZOOKEEPER_DATA_DIR/myid"
    
    
    echo "Editing regionservers conf regionservers - 나중에 보완할 필요...."
    pdsh -w ^all_hosts "echo    '   big01
    big02
    big03' >  ${HBASE_CONF_DIR}/regionservers"
    
    
	echo "Creating base Hadoop XML config files..."
	create_config --file core-site.xml
    put_config --file core-site.xml --property fs.defaultFS --value "hdfs://$DFS_NAMESERVICES"
    put_config --file core-site.xml --property dfs.journalnode.edits.dir --value "$JN_EDITS_DIR"
    put_config --file core-site.xml --property hadoop.http.staticuser.user --value "$HTTP_STATIC_USER"
    
    ## For Automatic Failover ...
    put_config --file core-site.xml --property ha.zookeeper.quorum --value "$HA_ZOOKEEPER_QUORUM"


    create_config --file hdfs-site.xml
    put_config --file hdfs-site.xml --property dfs.nameservices --value "$DFS_NAMESERVICES"
    put_config --file hdfs-site.xml --property dfs.ha.namenodes."$DFS_NAMESERVICES" --value "nn1,nn2"
    put_config --file hdfs-site.xml --property dfs.namenode.rpc-address."$DFS_NAMESERVICES".nn1 --value "$nn:8020"
    put_config --file hdfs-site.xml --property dfs.namenode.rpc-address."$DFS_NAMESERVICES".nn2 --value "$snn:8020"
    put_config --file hdfs-site.xml --property dfs.namenode.http-address."$DFS_NAMESERVICES".nn1 --value "$nn:50070"
    put_config --file hdfs-site.xml --property dfs.namenode.http-address."$DFS_NAMESERVICES".nn2 --value "$snn:50070"
    put_config --file hdfs-site.xml --property dfs.namenode.name.dir --value "$NN_DATA_DIR"
    put_config --file hdfs-site.xml --property dfs.datanode.data.dir --value "$DN_DATA_DIR"
    
    put_config --file hdfs-site.xml --property dfs.namenode.shared.edits.dir --value "$NAMENODE_SHARED_EDITS_DIR"
    put_config --file hdfs-site.xml --property dfs.client.failover.proxy.provider."$DFS_NAMESERVICES" --value "org.apache.hadoop.hdfs.server.namenode.ha.ConfiguredFailoverProxyProvider"
    
    ## fencing 설정과 ... dfs.ha.fencing.ssh.private-key-files 의 정확한 의미를 파악해야 함.....
    ## JounalNode를 사용하는 경우 fencing은 내부적으로 처리하는 것으로 판단 : https://hadoopabcd.wordpress.com/2015/02/19/hdfs-cluster-high-availability/
    ## 그런데 아래 설정을 지우면 에러가 나는 것은 왜지???
    put_config --file hdfs-site.xml --property dfs.ha.fencing.methods --value "sshfence"
    put_config --file hdfs-site.xml --property dfs.ha.fencing.ssh.private-key-files --value "/root/.ssh/id_rsa"
    
    #ZKFailoverController (ZKFC) is a new component which is a ZooKeeper
    put_config --file hdfs-site.xml --property dfs.ha.automatic-failover.enabled --value true
    

    create_config --file yarn-site.xml
    put_config --file yarn-site.xml --property yarn.nodemanager.aux-services --value mapreduce_shuffle
    put_config --file yarn-site.xml --property yarn.nodemanager.aux-services.mapreduce_shuffle.class --value org.apache.hadoop.mapred.ShuffleHandler
    put_config --file yarn-site.xml --property yarn.web-proxy.address --value "$yarn_proxy:$YARN_PROXY_PORT"
    put_config --file yarn-site.xml --property yarn.resourcemanager.scheduler.address --value "$rmgr:8030"
    put_config --file yarn-site.xml --property yarn.resourcemanager.resource-tracker.address --value "$rmgr:8031"
    put_config --file yarn-site.xml --property yarn.resourcemanager.address --value "$rmgr:8032"
    put_config --file yarn-site.xml --property yarn.resourcemanager.admin.address --value "$rmgr:8033"
    put_config --file yarn-site.xml --property yarn.resourcemanager.webapp.address --value "$rmgr:8088"
    put_config --file yarn-site.xml --property yarn.log-aggregation-enable --value true
    # for VM Memory Management  by warmpark
    put_config --file yarn-site.xml --property yarn.nodemanager.resource.memory-mb --value 4096
    put_config --file yarn-site.xml --property yarn.scheduler.minimum-allocation-mb --value 256 
    put_config --file yarn-site.xml --property yarn.scheduler.maximum-allocation-mb --value 768
    put_config --file yarn-site.xml --property yarn.nodemanager.vmem-check-enabled --value true
    put_config --file yarn-site.xml --property yarn.nodemanager.vmem-pmem-ratio --value 5.1
    put_config --file yarn-site.xml --property yarn.nodemanager.resource.cpu-vcores --value 2
    put_config --file yarn-site.xml --property yarn.scheduler.maximum-allocation-vcores --value 4

	
	create_config --file mapred-site.xml
	put_config --file mapred-site.xml --property mapreduce.framework.name --value yarn
	put_config --file mapred-site.xml --property mapreduce.jobhistory.address --value "$mr_hist:10020"
	put_config --file mapred-site.xml --property mapreduce.jobhistory.webapp.address --value "$mr_hist:19888"
	put_config --file mapred-site.xml --property yarn.app.mapreduce.am.staging-dir --value /mapred
	# for VM Memory Management  by warmpark	
	put_config --file mapred-site.xml --property yarn.app.mapreduce.am.resource.mb --value 768
	put_config --file mapred-site.xml --property mapreduce.map.memory.mb --value 408 
    put_config --file mapred-site.xml --property mapreduce.reduce.memory.mb --value 408 
    put_config --file mapred-site.xml --property mapreduce.map.java.opts --value "-Xmx384m" 
    put_config --file mapred-site.xml --property mapreduce.reduce.java.opts --value "-Xmx384m" 
    put_config --file mapred-site.xml --property mapreduce.task.io.sort.mb --value 128 
    
    
    ## HBASE -- 확인 후 변수화 해야 
	create_config --file hbase-site.xml
    put_config --file hbase-site.xml --property hbase.rootdir --value "hdfs://big01:8020/hbase"
    put_config --file hbase-site.xml --property hbase.master --value "big01:6000"
    put_config --file hbase-site.xml --property hbase.zookeeper.quorum --value "${HA_ZOOKEEPER_QUORUM}"
    put_config --file hbase-site.xml --property hbase.zookeeper.property.dataDir --value "${ZOOKEEPER_DATA_DIR}"
    put_config --file hbase-site.xml --property hbase.cluster.distributed --value true
    put_config --file hbase-site.xml --property dfs.datanode.max.xcievers --value 4096


    echo "Copying base Hadoop XML config files to all hosts..."
	pdcp -w ^all_hosts core-site.xml hdfs-site.xml mapred-site.xml yarn-site.xml $HADOOP_CONF_DIR
    
    echo "Copying HBASE XML config files to all hosts..."
	pdcp -w ^all_hosts hbase-site.xml $HBASE_HOME/etc/hadoop/
    
    echo "Copying the slaves file on each all hosts, in $HADOOP_CONF_DIR .... "
	pdcp -w ^all_hosts  dn_hosts $HADOOP_CONF_DIR/slaves
    pdcp -w ^all_hosts  jn_hosts $HADOOP_CONF_DIR/journalnodes
    
    

	echo "Creating configuration, command, and script links on all hosts..."
	pdsh -w ^all_hosts "ln -s $HADOOP_CONF_DIR /etc/hadoop"
	pdsh -w ^all_hosts "ln -s $HADOOP_HOME/bin/* /usr/bin"
	pdsh -w ^all_hosts "ln -s $HADOOP_HOME/libexec/* /usr/libexec"
    pdsh -w ^all_hosts "ln -s $ZOOKEEPER_CONF_DIR/* /etc/zookeeper"
	pdsh -w ^all_hosts "ln -s $ZOOKEEPER_HOME/bin/* /usr/bin"
    pdsh -w ^all_hosts "ln -s $HBASE_HOME/conf/* /etc/zookeeper"
	pdsh -w ^all_hosts "ln -s $HBASE_HOME/bin/*hbase* /usr/bin"


    echo "Copying startup scripts to all hosts..."
	#pdcp -w ^all_hosts hadoop-namenode /etc/init.d/
	#pdcp -w ^all_hosts hadoop-secondarynamenode /etc/init.d/
	#pdcp -w ^all_hosts hadoop-datanode /etc/init.d/
	#pdcp -w ^all_hosts hadoop-resourcemanager /etc/init.d/
	#pdcp -w ^all_hosts hadoop-nodemanager /etc/init.d/
	#pdcp -w ^all_hosts hadoop-historyserver /etc/init.d/
	#pdcp -w ^all_hosts hadoop-proxyserver /etc/init.d/
    #pdcp -w ^all_hosts hadoop-zookeeper /etc/init.d/
    


    
  
    echo "#1. Start ZK Quarum Daemon(su - hdfs -c '$ZOOKEEPER_HOME/bin/zkServer.sh start') :모든 ZK에서:  3,5 ... 홀수개수로 "
    pdsh -w ^zk_hosts "su - hdfs -c '$ZOOKEEPER_HOME/bin/zkServer.sh start'"

    echo "#2. ZK 내에 NameNode 이중화 관련 ZK 정보 초기화(su - hdfs -c '$HADOOP_HOME/bin/hdfs zkfc -formatZK'):Active NameNode 후보에서만: 반드시 ZK 가 실행 중이어야 함"
    #su - hdfs -c '$HADOOP_HOME/bin/hdfs zkfc -formatZK'
    pdsh -w ^nn_host "su - hdfs -c '$HADOOP_HOME/bin/hdfs zkfc -formatZK'"

    echo "#3. Start JournalNode Daemon(su - hdfs -c '$HADOOP_HOME/sbin/hadoop-daemon.sh start journalnode'):모든 JN에서: ZK Node와 동일하게 설치해야 하나? 그럴 필요 없어요 : 3,5 ... 홀수개"
    pdsh -w ^jn_hosts "su - hdfs -c '$HADOOP_HOME/sbin/hadoop-daemon.sh start journalnode'"

    echo "#4. Active Name Node  포멧(su - hdfs -c '$HADOOP_HOME/bin/hdfs namenode -format'):Active NameNode 후보에서만: 저널노드가 실행되고 있어야 함"
    #su - hdfs -c '$HADOOP_HOME/bin/hdfs namenode -format'
    pdsh -w ^nn_host "su - hdfs -c '$HADOOP_HOME/bin/hdfs namenode -format'"
    #pdsh -w ^nns_host "su - hdfs -c '$HADOOP_HOME/bin/hdfs namenode -format'"

    echo "#5. Start DataNode Daemon(su - hdfs -c '$HADOOP_HOME/sbin/hadoop-daemon.sh  start datanode'):모든 DN에서:"
    pdsh -w ^dn_hosts "su - hdfs -c '$HADOOP_HOME/sbin/hadoop-daemon.sh  start datanode'"

    echo "#6. Start Active NameNode Daemon(su - hdfs -c '$HADOOP_HOME/sbin/hadoop-daemon.sh start namenode')"
    pdsh -w ^nn_host "su - hdfs -c '$HADOOP_HOME/sbin/hadoop-daemon.sh start namenode'"
    #pdsh -w ^snn_host "su - hdfs -c '$HADOOP_HOME/sbin/hadoop-daemon.sh start namenode'"
    

    echo "#7. Start ZK Failover Controller Daemon(su - hdfs -c '$HADOOP_HOME/sbin/hadoop-daemon.sh start zkfc'):각 Name Node 마다:Name Node와 ZKFC의 실행 순서는 중요하지 않음. "
    pdsh -w ^nn_host "su - hdfs -c '$HADOOP_HOME/sbin/hadoop-daemon.sh start zkfc'"
    pdsh -w ^snn_host "su - hdfs -c '$HADOOP_HOME/sbin/hadoop-daemon.sh start zkfc'"

    echo "#8. Active Name Node의 filesystem 데이터를 Stand-by Name Node로 복사(su - hdfs -c '$HADOOP_HOME/bin/hdfs namenode -bootstrapStandby') :Stand-by Name Node에서만:"
    pdsh -w ^snn_host "su - hdfs -c '$HADOOP_HOME/bin/hdfs namenode -bootstrapStandby'"
    
    
    echo "#9. Start Stand-by NameNode Daemon(su - hdfs -c '$HADOOP_HOME/sbin/hadoop-daemon.sh start namenode') : Stand-by NN에서 : "
    #pdsh -w ^nn_host "su - hdfs -c '$HADOOP_HOME/sbin/hadoop-daemon.sh start namenode'"
    pdsh -w ^snn_host "su - hdfs -c '$HADOOP_HOME/sbin/hadoop-daemon.sh start namenode'"
    

    #"#. Name Node의 데이터를 Journal Node에 초기화 (Stand-by Name Node에서 실행) : hdfs namenode -initializeSharedEdits"
    ## 이부분은 나중에 수행 된 후 어떤 녀석이 Active인지 확인하고 해 주면 OK. ...  : 사용할 필요가 없을 듯..  초기 설치시.....에는 
    #pdsh -w ^snn_host "su - hdfs -c '$HADOOP_HOME/bin/hdfs namenode -initializeSharedEdits'"

    echo "## 이하   yarn "
    echo "#10. Start resource manager(su - yarn -c '$HADOOP_HOME/sbin/yarn-daemon.sh start resourcemanager'):RM에서: "
    pdsh -w ^rm_host "su - yarn -c '$HADOOP_HOME/sbin/yarn-daemon.sh start resourcemanager'"
    echo "#11. Start NodeManagers(su - yarn -c '$HADOOP_HOME/sbin/yarn-daemon.sh  start nodemanager'): NM에서 : NM은 DN이 있으면 하나씩 "
    pdsh -w ^nm_hosts "su - yarn -c '$HADOOP_HOME/sbin/yarn-daemon.sh  start nodemanager'"

    echo "#12. Start proxy server(su - yarn -c '$HADOOP_HOME/sbin/yarn-daemon.sh start proxyserver') "
    pdsh -w ^yarn_proxy_host "su - yarn -c '$HADOOP_HOME/sbin/yarn-daemon.sh start proxyserver'"

           
	echo "#13.Creating MapReduce Job History directories... mr-jobhistory-daemon.sh  start historyserver 수행하기 위해 필수..."
	su - hdfs -c "hdfs dfs -mkdir -p /mapred/history/done_intermediate"
	su - hdfs -c "hdfs dfs -chown -R mapred:hadoop /mapred"
	su - hdfs -c "hdfs dfs -chmod -R g+rwx /mapred"
    
    echo "#14. Start History Server(su - mapred -c '$HADOOP_HOME/sbin/mr-jobhistory-daemon.sh  start historyserver') "
    pdsh -w ^mr_history_host "su - mapred -c '$HADOOP_HOME/sbin/mr-jobhistory-daemon.sh  start historyserver'"
    
   
    #pdsh -w ^nn_host "su - hdfs -c '$HADOOP_HOME/sbin/start-dfs.sh'"
    #pdsh -w ^nn_host "su - yarn -c '$HADOOP_HOME/sbin/start-yarn.sh'"
    
    
    echo "#15. Start HBASE Server(su - hbase -c '$HBASE_HOME/bin/start-hbase.sh') "
    pdsh -w ^nn_host "su - hbase -c '$HBASE_HOME/bin/start-hbase.sh'"
    
 

	echo "#16. Running YARN smoke test..."
	pdsh -w ^all_hosts "usermod -a -G hadoop $(whoami)"
	su - hdfs -c "hadoop fs -mkdir -p /user/$(whoami)"
	su - hdfs -c "hadoop fs -chown $(whoami):$(whoami) /user/$(whoami)"
	source /etc/profile.d/java.sh
	source /etc/profile.d/hadoop.sh
	source /etc/hadoop/hadoop-env.sh
	source /etc/hadoop/yarn-env.sh
	hadoop jar $HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-examples-$HADOOP_VERSION.jar pi -Dmapreduce.clientfactory.class.name=org.apache.hadoop.mapred.YarnClientFactory -libjars $HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-client-jobclient-$HADOOP_VERSION.jar 16 10000
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
