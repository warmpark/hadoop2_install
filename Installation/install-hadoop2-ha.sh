#!/bin/bash
# Install Hadoop 2 using pdsh/pdcp where possible.
# 
# Command can be interactive or file-based.  This script sets up
# a Hadoop 2 cluster with basic configuration.  Modify data, log, and pid
# directories as desired.  Further configure your cluster with ./conf-hadoop2.sh
# after running this installation script.
#

. $(dirname "$0")/config-hadoop2-ha.sh


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

    ## PHOENIX DOWNLOAD
    phoenixfile=./apache-phoenix-${PHOENIX_VERSION}-HBase-${PHOENIX_HBASE_VERSION}-bin.tar.gz
    if [ ! -e "$phoenixfile" ]; then
        echo "File does not exist"
        wget ${HOENIX_DOWNLOAD_URI}
    else 
        echo "PHOENIX File exists"
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

	echo "Creating system accounts and groups on all hosts..."
	# useradd 계정명 -m -s /bin/bash
	#→ -m 옵션을 명시해야 홈 디렉토리가 생성됨
	#-s /bin/bash 옵션을 명시해야 쉘 환경이 설정됨
	
	pdsh -w ^all_hosts groupadd hadoop
	pdsh -w ^all_hosts useradd -g hadoop yarn -m -s /bin/bash
	pdsh -w ^all_hosts useradd -g hadoop hdfs -m -s /bin/bash
	pdsh -w ^all_hosts useradd -g hadoop mapred -m -s /bin/bash
    pdsh -w ^all_hosts useradd -g hadoop hbase -m -s /bin/bash
    pdsh -w ^all_hosts useradd -g hadoop kafka -m -s /bin/bash
    pdsh -w ^all_hosts useradd -g hadoop storm -m -s /bin/bash
    pdsh -w ^all_hosts useradd -g hadoop nifi -m -s /bin/bash
	    
    echo "Copying hadoop-"$HADOOP_VERSION".tar.gz,  zookeeper-"$ZOOKEEPER_VERSION".tar.gz, hbase-${HBASE_VERSION}-bin.tar.gz, kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz, apache-storm-${STORM_VERSION}.tar.gz, nifi-${NIFI_VERSION}-bin.tar.gz to all hosts..."
	pdcp -w ^all_hosts hadoop-${HADOOP_VERSION}.tar.gz /opt
    pdcp -w ^all_hosts zookeeper-${ZOOKEEPER_VERSION}.tar.gz /opt
    pdcp -w ^all_hosts hbase-${HBASE_VERSION}-bin.tar.gz /opt
	pdcp -w ^all_hosts apache-phoenix-${PHOENIX_VERSION}-HBase-${PHOENIX_HBASE_VERSION}-bin.tar.gz /opt
	pdcp -w ^all_hosts kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz /opt
	pdcp -w ^all_hosts apache-storm-${STORM_VERSION}.tar.gz /opt
	pdcp -w ^all_hosts nifi-${NIFI_VERSION}-bin.tar.gz /opt  
	pdsh -w ^all_hosts "su - hdfs -c 'cp -f ${PHOENIX_HOME}/apache-phoenix-${PHOENIX_VERSION}-HBase-${PHOENIX_HBASE_VERSION}-server.jar  $HBASE_HOME/lib '"
		
	
if [ -z "$JAVA_HOME" ]; then
	echo "Download & Copying JDK ${JDK_VERSION} to all hosts...${JDK_DOWNLOAD_URI}"
  ## JDK DOWNLOAD
    if [ ! -e "$JDK_RPM_NAME" ]; then
        echo "JDK PRM File does not exist"
        wget --no-cookies --no-check-certificate --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" ${JDK_DOWNLOAD_URI}
		#wget --no-cookies --no-check-certificate --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" "http://download.oracle.com/otn-pub/java/jdk/8u131-b11/d54c1d3a095b4ff2b6607d096fa80163/jdk-8u131-linux-x64.rpm"

  else 
        echo "JDK PRM File exists"
    fi
     echo "Copying  ${JDK_RPM_NAME} to all hosts..."
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
    
    
 
	
	######  압축 해제... 
    echo "Extracting Hadoop hadoop-$HADOOP_VERSION.tar.gz distribution on all hosts..."
	pdsh -w ^all_hosts "tar -zxf /opt/hadoop-$HADOOP_VERSION.tar.gz -C /opt && chown -R hdfs:hadoop ${HADOOP_HOME}"

    echo "Extracting Zookeeper zookeeper-$ZOOKEEPER_VERSION.tar.gz distribution on all ZK hosts..."
	pdsh -w ^zk_hosts  "tar -zxf /opt/zookeeper-$ZOOKEEPER_VERSION.tar.gz -C /opt && chown -R hdfs:hadoop ${ZOOKEEPER_HOME}"

    echo "Extracting HBASE hbase-$HBASE_VERSION-bin.tar.gz distribution on all hosts..."
	pdsh -w ^all_hosts "tar -zxf /opt/hbase-$HBASE_VERSION-bin.tar.gz -C /opt && chown -R hdfs:hadoop ${HBASE_HOME}"
 
	echo "Extracting KAFKA kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz distribution on all hosts..."
	pdsh -w ^all_hosts "tar -xzf /opt/kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz -C /opt && chown -R hdfs:hadoop ${KAFKA_HOME}"

	echo "Extracting STORM apache-storm-${STORM_VERSION}.tar.gz distribution on all hosts..."
	pdsh -w ^all_hosts "tar -xzf /opt/apache-storm-${STORM_VERSION}.tar.gz -C /opt && chown -R hdfs:hadoop ${STORM_HOME}"

	echo "Extracting NIFI nifi-${NIFI_VERSION}-bin.tar.gz distribution on all hosts..."
	pdsh -w ^all_hosts "tar -zxf /opt/nifi-${NIFI_VERSION}-bin.tar.gz -C /opt && chown -R hdfs:hadoop ${NIFI_HOME}"
	
	echo "Extracting PHOENIX apache-phoenix-${PHOENIX_VERSION}-HBase-${PHOENIX_HBASE_VERSION}-bin.tar.gz distribution on all hosts..."
	pdsh -w ^zk_hosts  "tar -xzf /opt/apache-phoenix-${PHOENIX_VERSION}-HBase-${PHOENIX_HBASE_VERSION}-bin.tar.gz -C /opt && chown -R hdfs:hadoop ${PHOENIX_HOME}"
	pdsh -w ^all_hosts "su - hdfs -c 'cp -f ${PHOENIX_HOME}/phoenix-${PHOENIX_VERSION}-HBase-${PHOENIX_HBASE_VERSION}-server.jar  $HBASE_HOME/lib '"

	
	
	#### /etc/profile.d/xxx.sh 생성.... 
	
	pdsh -w ^all_hosts "echo export HADOOP_HOME=$HADOOP_HOME > /etc/profile.d/hadoop.sh"
	pdsh -w ^all_hosts "echo export HADOOP_PREFIX=$HADOOP_HOME >> /etc/profile.d/hadoop.sh"
    pdsh -w ^all_hosts "echo export HADOOP_CONF_DIR=$HADOOP_CONF_DIR >> /etc/profile.d/hadoop.sh"
	##HADOOP Native Lib .
	pdsh -w ^all_hosts echo "export HADOOP_COMMON_LIB_NATIVE_DIR=\\\${HADOOP_PREFIX}/lib/native >> /etc/profile.d/hadoop.sh"
	pdsh -w ^all_hosts echo "export HADOOP_OPTS=\\\"-Djava.library.path=\\\${HADOOP_PREFIX}/lib/native\\\" >> /etc/profile.d/hadoop.sh"
	pdsh -w ^all_hosts "source /etc/profile.d/hadoop.sh"
    
	pdsh -w ^zk_hosts "echo export ZOOKEEPER_HOME=$ZOOKEEPER_HOME > /etc/profile.d/zookeeper.sh"
	#pdsh -w ^zk_hosts "echo export ZOOKEEPER_PREFIX=$ZOOKEEPER_HOME >> /etc/profile.d/zookeeper.sh"
	pdsh -w ^zk_hosts "echo export ZOOKEEPER_LOG_DIR=$ZOOKEEPER_LOG_DIR >> /etc/profile.d/zookeeper.sh"
	pdsh -w ^zk_hosts "echo export ZOOKEEPER_CONF_DIR=$ZOOKEEPER_CONF_DIR >> /etc/profile.d/zookeeper.sh"
	pdsh -w ^zk_hosts "echo export ZOO_LOG_DIR=$ZOOKEEPER_LOG_DIR >> /etc/profile.d/zookeeper.sh"
	pdsh -w ^zk_hosts "source /etc/profile.d/zookeeper.sh"
    ## HBASE && PHOENIX
    pdsh -w ^all_hosts "echo export HBASE_HOME=$HBASE_HOME > /etc/profile.d/hbase.sh"
	pdsh -w ^all_hosts "echo export HBASE_PREFIX=$HBASE_HOME >> /etc/profile.d/hbase.sh"
	pdsh -w ^all_hosts "echo export HBASE_CONF_DIR=$HBASE_CONF_DIR >> /etc/profile.d/hbase.sh"
	pdsh -w ^all_hosts "echo export HBASE_LOG_DIR=$HBASE_LOG_DIR >> /etc/profile.d/hbase.sh"
    pdsh -w ^all_hosts "echo export PATH=$HBASE_HOME/bin:$PATH >> /etc/profile.d/hbase.sh"
    pdsh -w ^all_hosts "echo export CLASSPATH=$CLASSPATH:$HBASE_CONF_DIR >> /etc/profile.d/hbase.sh"

    pdsh -w ^all_hosts "echo export PHOENIX_HOME=$PHOENIX_HOME >> /etc/profile.d/hbase.sh"
	pdsh -w ^all_hosts "echo export PHOENIX_PREFIX=$PHOENIX_HOME >> /etc/profile.d/hbase.sh"
	pdsh -w ^all_hosts "echo export PHOENIX_CONF_DIR=$PHOENIX_CONF_DIR >> /etc/profile.d/hbase.sh"
	pdsh -w ^all_hosts "echo export PHOENIX_LOG_DIR=$PHOENIX_LOG_DIR >> /etc/profile.d/hbase.sh"
    pdsh -w ^all_hosts "echo export PATH=$PHOENIX_HOME/bin:$PATH >> /etc/profile.d/hbase.sh"
    pdsh -w ^all_hosts "echo export CLASSPATH=$CLASSPATH:$PHOENIX_CONF_DIR >> /etc/profile.d/hbase.sh"
	
	pdsh -w ^all_hosts "source /etc/profile.d/hbase.sh"
	
	pdsh -w ^all_hosts "echo export KAFKA_HOME=$KAFKA_HOME > /etc/profile.d/kafka.sh"
	pdsh -w ^all_hosts "echo export KAFKA_PREFIX=$KAFKA_HOME >> /etc/profile.d/kafka.sh"
	pdsh -w ^all_hosts "echo export KAFKA_CONF_DIR=$KAFKA_CONF_DIR >> /etc/profile.d/kafka.sh"
	pdsh -w ^all_hosts "echo export KAFKA_LOG_DIR=$KAFKA_LOG_DIR >> /etc/profile.d/kafka.sh"
    pdsh -w ^all_hosts "echo export PATH=$KAFKA_HOME/bin:$PATH >> /etc/profile.d/kafka.sh"
    pdsh -w ^all_hosts "echo export CLASSPATH=$CLASSPATH:$KAFKA_CONF_DIR >> /etc/profile.d/kafka.sh"
	pdsh -w ^all_hosts "source /etc/profile.d/kafka.sh"

    pdsh -w ^all_hosts "echo export STORM_HOME=$STORM_HOME > /etc/profile.d/storm.sh"
	pdsh -w ^all_hosts "echo export STORM_PREFIX=$STORM_HOME >> /etc/profile.d/storm.sh"
	pdsh -w ^all_hosts "echo export STORM_CONF_DIR=$STORM_CONF_DIR >> /etc/profile.d/storm.sh"
	pdsh -w ^all_hosts "echo export STORM_LOG_DIR=$STORM_LOG_DIR >> /etc/profile.d/storm.sh"
    pdsh -w ^all_hosts "echo export PATH=$STORM_HOME/bin:$PATH >> /etc/profile.d/storm.sh"
    pdsh -w ^all_hosts "echo export CLASSPATH=$CLASSPATH:$STORM_CONF_DIR >> /etc/profile.d/storm.sh"
	pdsh -w ^all_hosts "source /etc/profile.d/storm.sh"

    
    pdsh -w ^all_hosts "echo export NIFI_HOME=$NIFI_HOME > /etc/profile.d/nifi.sh"
	pdsh -w ^all_hosts "echo export NIFI_PREFIX=$NIFI_HOME >> /etc/profile.d/nifi.sh"
	pdsh -w ^all_hosts "echo export NIFI_CONF_DIR=$NIFI_CONF_DIR >> /etc/profile.d/nifi.sh"
	pdsh -w ^all_hosts "echo export NIFI_LOG_DIR=$NIFI_LOG_DIR >> /etc/profile.d/nifi.sh"
    pdsh -w ^all_hosts "echo export PATH=$NIFI_HOME/bin:$PATH >> /etc/profile.d/nifi.sh"
    pdsh -w ^all_hosts "echo export CLASSPATH=$CLASSPATH:$NIFI_CONF_DIR >> /etc/profile.d/nifi.sh"
	pdsh -w ^all_hosts "source /etc/profile.d/nifi.sh"

    ## log dir    
    echo "Editing Hadoop environment scripts for log directories on all hosts..."
	pdsh -w ^all_hosts echo "export HADOOP_LOG_DIR=$HADOOP_LOG_DIR >> $HADOOP_CONF_DIR/hadoop-env.sh"
	pdsh -w ^all_hosts echo "export YARN_LOG_DIR=$YARN_LOG_DIR >> $HADOOP_CONF_DIR/yarn-env.sh"
	pdsh -w ^all_hosts echo "export HADOOP_MAPRED_LOG_DIR=$HADOOP_MAPRED_LOG_DIR >> $HADOOP_CONF_DIR/mapred-env.sh"
	
	## pid dir 
	echo "Editing Hadoop environment scripts for pid directories on all hosts..."
	pdsh -w ^all_hosts echo "export HADOOP_PID_DIR=$HADOOP_PID_DIR >> $HADOOP_CONF_DIR/hadoop-env.sh"
	pdsh -w ^all_hosts echo "export YARN_PID_DIR=$YARN_PID_DIR >> $HADOOP_CONF_DIR/yarn-env.sh"
	pdsh -w ^all_hosts echo "export HADOOP_MAPRED_PID_DIR=$HADOOP_MAPRED_PID_DIR >> $HADOOP_CONF_DIR/mapred-env.sh"
    pdsh -w ^all_hosts echo "export HBASE_PID_DIR=$HBASE_PID_DIR >> $HBASE_CONF_DIR/hbase-env.sh"
    ### ZK  PID관리는 어떻게.....
	
	
	## 설정파일 다시 로드 
	pdsh -w ^all_hosts "source /etc/profile.d/hadoop.sh"
	pdsh -w ^zk_hosts "source /etc/profile.d/zookeeper.sh"
	pdsh -w ^all_hosts "source /etc/profile.d/hbase.sh"
	
	pdsh -w ^all_hosts "source /etc/profile.d/kafka.sh"
	pdsh -w ^all_hosts "source /etc/profile.d/storm.sh"
	pdsh -w ^all_hosts "source /etc/profile.d/nifi.sh"

	
    ### 각종 저장 장소의 기본 사용자는 hdfs... 

	echo "Creating hadoop data dir, log dir, pid dir ..."
    pdsh -w ^all_hosts "mkdir -p ${HADOOP_DATA_DIR} && chown -R hdfs:hadoop ${HADOOP_DATA_DIR}"
    pdsh -w ^all_hosts "mkdir -p /var/log/hadoop && chown -R hdfs:hadoop /var/log/hadoop"
    pdsh -w ^all_hosts "mkdir -p /var/run/hadoop && chown -R hdfs:hadoop /var/run/hadoop"
	
    
	echo "Creating HDFS data directories on NameNode host, JournalNode hosts, Secondary NameNode host, and DataNode hosts..."
    #pdsh -w ^all_hosts "mkdir -p $NN_DATA_DIR && chown hdfs:hadoop $NN_DATA_DIR"
    pdsh -w ^all_hosts "mkdir -p $NN_DATA_DIR && chown -R hdfs:hadoop $NN_DATA_DIR"
	pdsh -w ^all_hosts "mkdir -p $DN_DATA_DIR && chown -R hdfs:hadoop $DN_DATA_DIR"
    pdsh -w ^all_hosts "mkdir -p $JN_EDITS_DIR && chown -R hdfs:hadoop $JN_EDITS_DIR"
    pdsh -w ^all_hosts "mkdir -p $ZOOKEEPER_DATA_DIR && chown -R hdfs:hadoop $ZOOKEEPER_DATA_DIR"
    #HBASE
    pdsh -w ^all_hosts "mkdir -p ${HBASE_DATA_DIR} && chown -R hdfs:hadoop ${HBASE_DATA_DIR}"
    #KAFKA
    pdsh -w ^all_hosts "mkdir -p ${KAFKA_DATA_DIR} && chown -R hdfs:hadoop ${KAFKA_DATA_DIR}"
    #STORM
    pdsh -w ^all_hosts "mkdir -p ${STORM_DATA_DIR} && chown -R hdfs:hadoop ${STORM_DATA_DIR}"
    #NIFI
    pdsh -w ^all_hosts "mkdir -p ${NIFI_DATA_DIR} && chown -R hdfs:hadoop ${NIFI_DATA_DIR}"
	
        

	echo "Creating log directories on all hosts..."
	pdsh -w ^all_hosts "mkdir -p $YARN_LOG_DIR && chown -R yarn:hadoop $YARN_LOG_DIR"
	pdsh -w ^all_hosts "mkdir -p $HADOOP_LOG_DIR && chown -R hdfs:hadoop $HADOOP_LOG_DIR"
	pdsh -w ^all_hosts "mkdir -p $HADOOP_MAPRED_LOG_DIR && chown -R mapred:hadoop $HADOOP_MAPRED_LOG_DIR"
    pdsh -w ^all_hosts "mkdir -p $ZOOKEEPER_LOG_DIR && chown -R hdfs:hadoop $ZOOKEEPER_LOG_DIR"
    ## HBASE
    pdsh -w ^all_hosts "mkdir -p ${HBASE_LOG_DIR} && chown -R hdfs:hadoop ${HBASE_LOG_DIR}"
    #KAFKA
    pdsh -w ^all_hosts "mkdir -p ${KAFKA_LOG_DIR} && chown -R hdfs:hadoop ${KAFKA_LOG_DIR}"
    #STORM
    pdsh -w ^all_hosts "mkdir -p ${STORM_LOG_DIR} && chown -R hdfs:hadoop ${STORM_LOG_DIR}"
    #NIFI
    pdsh -w ^all_hosts "mkdir -p ${NIFI_LOG_DIR} && chown -R hdfs:hadoop ${NIFI_LOG_DIR}"
   

	echo "Creating pid directories on all hosts..."
	pdsh -w ^all_hosts "mkdir -p $YARN_PID_DIR && chown -R yarn:hadoop $YARN_PID_DIR"
	pdsh -w ^all_hosts "mkdir -p $HADOOP_PID_DIR && chown -R hdfs:hadoop $HADOOP_PID_DIR"
	pdsh -w ^all_hosts "mkdir -p $HADOOP_MAPRED_PID_DIR && chown -R mapred:hadoop $HADOOP_MAPRED_PID_DIR"
    pdsh -w ^all_hosts "mkdir -p $HBASE_PID_DIR && chown -R hdfs:hadoop $HBASE_PID_DIR"
    ##TODO JK PID는 어떻게 ? 어디에 ? 구글링해봐야...
    #KAFKA
    pdsh -w ^all_hosts "mkdir -p ${KAFKA_PID_DIR} && chown -R hdfs:hadoop ${KAFKA_PID_DIR}"
    #STORM
    pdsh -w ^all_hosts "mkdir -p ${STORM_PID_DIR} && chown -R hdfs:hadoop ${STORM_PID_DIR}"
    #NIFI
    pdsh -w ^all_hosts "mkdir -p ${NIFI_PID_DIR} && chown -R hdfs:hadoop ${NIFI_PID_DIR}"
   

	if [ -n "$YARN_NODEMANAGER_HEAPSIZE" ]
	then 
		echo "for VM Memory Management  by warmpark   Editing Hadoop yarn-env.sh environment for YARN_NODEMANAGER_HEAPSIZE on all hosts..."
		pdsh -w ^all_hosts echo "export YARN_NODEMANAGER_HEAPSIZE=$YARN_NODEMANAGER_HEAPSIZE >> $HADOOP_CONF_DIR/yarn-env.sh"
	fi
   
   
   	echo "HBASE hbase-env.sh"
    pdsh -w ^all_hosts echo "export HBASE_MANAGES_ZK=$HBASE_MANAGES_ZK >> $HBASE_CONF_DIR/hbase-env.sh"
		
	###### ZOOKEEPER    
	echo "Editing zookeeper conf zoo.cfg - TODO 나중에 보완할 필요...."
	pdsh -w ^all_hosts "echo     'dataDir=$ZOOKEEPER_DATA_DIR
	dataLogDir=$ZOOKEEPER_LOG_DIR
	clientPort=2181
	initLimit=5
	syncLimit=2
	server.1=big01:2888:3888
	server.2=big02:2888:3888
	server.3=big03:2888:3888' >  $ZOOKEEPER_CONF_DIR/zoo.cfg"

		
	echo "Make zookeeper id in  $ZOOKEEPER_DATA_DIR/myid - TODO 나중에 보완할 필요...."
	pdsh -w big01 "echo 1 > $ZOOKEEPER_DATA_DIR/myid"
	pdsh -w big02 "echo 2 > $ZOOKEEPER_DATA_DIR/myid"
	pdsh -w big03 "echo 3 > $ZOOKEEPER_DATA_DIR/myid"

		
	echo "Editing regionservers conf regionservers - 나중에 보완할 필요...  HBASE는 HMaster와 ResionServer가 동시에 수행될 수 없음.--> 확인필요."
	pdsh -w ^all_hosts "echo    'big02
	big03' >  $HBASE_CONF_DIR/regionservers"



	###### KAFKA
	echo "Editing zookeeper conf $KAFKA_CONF_DIR/zookeeper.properties - TODO 나중에 보완할 필요...."
	pdsh -w ^all_hosts "mv $KAFKA_CONF_DIR/zookeeper.properties $KAFKA_CONF_DIR/zookeeper.properties.org"

	pdsh -w ^all_hosts "echo     'dataDir=/var/data/zookeeper
	dataLogDir=/var/log/zookeeper
	clientPort=2181
	initLimit=5
	syncLimit=2
	maxClientCnxns=0
	server.1=big01:2888:3888
	server.2=big02:2888:3888
	server.3=big03:2888:3888' >  $KAFKA_CONF_DIR/zookeeper.properties"

	echo "Editing zookeeper conf $KAFKA_CONF_DIR/server.properties - TODO 나중에 보완할 필요...."
	## 백업 
	pdsh -w ^all_hosts "mv $KAFKA_CONF_DIR/server.properties $KAFKA_CONF_DIR/server.properties.org"
	## server.properties 설정 
	pdsh -w ^all_hosts "echo     'broker.id=0
	delete.topic.enable=true
	zookeeper.connect=big01:2181,big02:2181,big03:2181

	#listeners=PLAINTEXT://:9092
	num.network.threads=3
	num.io.threads=8
	socket.send.buffer.bytes=102400
	socket.receive.buffer.bytes=102400
	socket.request.max.bytes=104857600
	log.dirs=$KAFKA_LOG_DIR
	num.partitions=1
	num.recovery.threads.per.data.dir=1
	#log.flush.interval.messages=10000
	#log.flush.interval.ms=1000
	log.retention.hours=168
	#log.retention.bytes=1073741824
	log.segment.bytes=1073741824
	log.retention.check.interval.ms=300000
	zookeeper.connection.timeout.ms=6000' >  $KAFKA_CONF_DIR/server.properties"
	## broker.id 설정 
	pdsh -w big01 "sed -i 's/broker.id=0/broker.id=1/g' $KAFKA_CONF_DIR/server.properties"
	pdsh -w big02 "sed -i 's/broker.id=0/broker.id=2/g' $KAFKA_CONF_DIR/server.properties"
	pdsh -w big03 "sed -i 's/broker.id=0/broker.id=3/g' $KAFKA_CONF_DIR/server.properties"


###### STORM
echo "Editing zookeeper conf $STORM_CONF_DIR//storm.yaml - TODO 나중에 보완할 필요...."
pdsh -w ^all_hosts "mv $STORM_CONF_DIR//storm.yaml $STORM_CONF_DIR//storm.yaml.org"

## "//t" 이 들어 있으면 안됨. 
pdsh -w ^all_hosts "echo     'storm.zookeeper.servers:
- "big01"
- "big02"
- "big03"
#storm.local.dir: "/tmp/storm"
storm.local.dir: "${STORM_DATA_DIR}"
storm.log.dir: "${STORM_LOG_DIR}"

nimbus.seeds: ["big01","big02", "big03"]

supervisor.slots.ports:
- 6700
- 6701
- 6702
- 6703

storm.health.check.dir: "healthchecks"
storm.health.check.timeout.ms: 5000' >  $STORM_CONF_DIR/storm.yaml"

###### NIFI


############
    
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
    
    
    ## HBASE -- 확인 후 변수화 해야   dfs.nameservices --value "$DFS_NAMESERVICES"
	create_config --file hbase-site.xml
    ## hdfs-site.xml dfs.nameservices --value "$DFS_NAMESERVICES"  from http://stackoverflow.com/questions/38769315/how-to-configure-hbase-in-a-ha-mode
    put_config --file hbase-site.xml --property hbase.rootdir --value "hdfs://$DFS_NAMESERVICES:8020/hbase"
    #put_config --file hbase-site.xml --property hbase.rootdir --value "hdfs://big01:8020/hbase"
    put_config --file hbase-site.xml --property hbase.master --value "big01:6000"
    put_config --file hbase-site.xml --property hbase.zookeeper.quorum --value "$HA_ZOOKEEPER_QUORUM"
    #put_config --file hbase-site.xml --property hbase.zookeeper.quorum --value "big01,big02,big03"
    put_config --file hbase-site.xml --property hbase.zookeeper.property.dataDir --value "$ZOOKEEPER_DATA_DIR"
    put_config --file hbase-site.xml --property hbase.cluster.distributed --value true
    put_config --file hbase-site.xml --property dfs.datanode.max.xcievers --value 4096

    echo "Copying base Hadoop XML config files to all hosts..."
	pdcp -w ^all_hosts core-site.xml hdfs-site.xml mapred-site.xml yarn-site.xml $HADOOP_CONF_DIR
    
    echo "Copying HBASE XML and Hadoop XML config files to all hosts..."
	pdcp -w ^all_hosts core-site.xml hdfs-site.xml mapred-site.xml yarn-site.xml hbase-site.xml $HBASE_CONF_DIR
    
    echo "Copying the slaves file on each all hosts, in $HADOOP_CONF_DIR .... "
	pdcp -w ^all_hosts  dn_hosts $HADOOP_CONF_DIR/slaves
    pdcp -w ^all_hosts  jn_hosts $HADOOP_CONF_DIR/journalnodes
    
    

	echo "Creating configuration, command, and script links on all hosts..."
	pdsh -w ^all_hosts "ln -s $HADOOP_CONF_DIR /etc/hadoop"
	pdsh -w ^all_hosts "ln -s $HADOOP_HOME/bin/* /usr/bin"
	pdsh -w ^all_hosts "ln -s $HADOOP_HOME/libexec/* /usr/libexec"
    pdsh -w ^all_hosts "ln -s $ZOOKEEPER_CONF_DIR /etc/zookeeper"
	pdsh -w ^all_hosts "ln -s $ZOOKEEPER_HOME/bin/zk* /usr/bin"
    pdsh -w ^all_hosts "ln -s $HBASE_CONF_DIR /etc/hbase"
	pdsh -w ^all_hosts "ln -s $HBASE_HOME/bin/*hbase* /usr/bin"
	
	pdsh -w ^all_hosts "ln -s $KAFKA_CONF_DIR /etc/kafka"
	pdsh -w ^all_hosts "ln -s $KAFKA_HOME/bin/*kafka* /usr/bin"
	pdsh -w ^all_hosts "ln -s $STORM_CONF_DIR /etc/storm"
	pdsh -w ^all_hosts "ln -s $STORM_HOME/bin/*storm* /usr/bin"
	pdsh -w ^all_hosts "ln -s $NIFI_CONF_DIR /etc/nifi"
	pdsh -w ^all_hosts "ln -s $NIFI_HOME/bin/*nifi* /usr/bin"


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
	sleep 20

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
	## HBASE를 hdfs계정으로 실행할 때, 아래 오류 해결 방안 찾아야... --> 일단은 root 계정으로 시작. 
	# big01: Java HotSpot(TM) 64-Bit Server VM warning: ignoring option PermSize=128m; support was removed in 8.0
	# big01: Java HotSpot(TM) 64-Bit Server VM warning: ignoring option MaxPermSize=128m; support was removed in 8.0
	# big01: big02: Host key verification failed.
	# big01: big03: Host key verification failed.
    # pdsh -w ^nn_host "su - hdfs -c '$HBASE_HOME/bin/start-hbase.sh'"
	pdsh -w ^nn_host "su - hdfs -c '$HBASE_HOME/bin/hbase-daemon.sh start master'"
	pdsh -w ^hbase_regionservers "su - hdfs -c '$HBASE_HOME/bin/hbase-daemon.sh start regionserver'"
	
	echo "#15. Start PHOENIX on HBASE Region Server(su - hdfs -c '$PHOENIX_HOME/bin/queryserver.py start') "
	pdsh -w ^hbase_regionservers "su - hdfs -c '$PHOENIX_HOME/bin/queryserver.py start'"

    
	echo "#16. Running YARN smoke test..."
	pdsh -w ^all_hosts "usermod -a -G hadoop $(whoami)"
	su - hdfs -c "hadoop fs -mkdir -p /user/$(whoami)"
	su - hdfs -c "hadoop fs -chown $(whoami):$(whoami) /user/$(whoami)"
	source /etc/profile.d/java.sh
	source /etc/profile.d/hadoop.sh
	source /etc/hadoop/hadoop-env.sh
	source /etc/hadoop/yarn-env.sh
	hadoop jar $HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-examples-$HADOOP_VERSION.jar pi -Dmapreduce.clientfactory.class.name=org.apache.hadoop.mapred.YarnClientFactory -libjars $HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-client-jobclient-$HADOOP_VERSION.jar 16 10000

	echo "#17. Start Kafka & create test topic"
	#pdsh -w ^all_hosts "rm -rf ${KAFKA_LOG_DIR}"
	pdsh -w ^all_hosts  "su - hdfs -c '${KAFKA_HOME}/bin/kafka-server-start.sh -daemon ${KAFKA_CONF_DIR}/server.properties'"
	sleep 30
	su - hdfs -c "${KAFKA_HOME}/bin/kafka-topics.sh --create --zookeeper  big01:2181,big02:2181,big03:2181 --replication-factor 3 --partitions 20 --topic test"
	su - hdfs -c "${KAFKA_HOME}/bin/kafka-topics.sh --create --zookeeper  big01:2181,big02:2181,big03:2181 --replication-factor 3 --partitions 3 --topic onlytest"
	su - hdfs -c "${KAFKA_HOME}/bin/kafka-topics.sh --list --zookeeper  big01:2181,big02:2181,big03:2181"
	su - hdfs -c "${KAFKA_HOME}/bin/kafka-topics.sh --describe --zookeeper  big01:2181,big02:2181,big03:2181 --topic test"

	echo "#18. Start Storm"
	## eval "nohup ${STORM_HOME}/bin/storm nimbus > ${STORM_LOG_DIR}/nimbus.log 2>&1 &"
	## NIMBUS_BACKGROUND_PID=$!
	## export NIMBUS_BACKGROUND_PID
	## echo $NIMBUS_BACKGROUND_PID > "${STORM_PID_DIR}/nimbus.pid"

	pdsh -w big01,big02,big03  "su - hdfs -c 'nohup ${STORM_HOME}/bin/storm nimbus > ${STORM_LOG_DIR}/nimbus.log 2>&1 &'"
	pdsh -w big01,big02,big03  "su - hdfs -c '${STORM_HOME}/bin/storm supervisor > ${STORM_LOG_DIR}/supervisor.log 2>&1 &'"
	pdsh -w big01,big02,big03  "su - hdfs -c '${STORM_HOME}/bin/storm ui > ${STORM_LOG_DIR}/ui.log 2>&1 &'"
	sleep 50
	#pdsh -w big02,big03  "su - hdfs -c 'nohup ${STORM_HOME}/bin/storm nimbus > ${STORM_LOG_DIR}/nimbus.log 2>&1 &'"
		
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
