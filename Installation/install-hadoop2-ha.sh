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

ZOOKEEPER_VERSION=3.4.8
ZOOKEEPER_HOME="/opt/zookeeper-${ZOOKEEPER_VERSION}"
ZOOKEEPER_LOG_DIR="${ZOOKEEPER_HOME}/logs"
ZOOKEEPER_PREFIX="${ZOOKEEPER_HOME}"

ZOOKEEPER_CONF_DIR="${ZOOKEEPER_HOME}/conf"
ZOOKEEPER_DATA_DIR="${ZOOKEEPER_HOME}/data"

DFS_NAMESERVICES=big-cluster
HA_ZOOKEEPER_QUORUM=big01:2181,big02:2181,big03:2181
JN_EDITS_DIR=/var/data/hadoop/journal/data
NAMENODE_SHARED_EDITS_DIR="qjournal://big01:8485;big02:8485;big03:8485/${DFS_NAMESERVICES}"



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
# If using local OpenJDK, it must be installed on all nodes.
# If using jdk-8u92-linux-x64.rpm, then
# set JAVA_HOME="" and place jdk-8u92-linux-x64.rpm in this directory
#JAVA_HOME=/usr/lib/jvm/java-1.6.0-openjdk-1.6.0.0.x86_64/
#JAVA_HOME=/usr/lib/jvm/java-1.7.0-openjdk-1.7.0.101-2.6.6.1.el7_2.x86_64/jre/
JAVA_HOME=""
source ./hadoop-xml-conf.sh
CMD_OPTIONS=$(getopt -n "$0"  -o hif --long "help,interactive,file"  -- "$@")
HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop

## VM Memory management by warmpark add.
YARN_NODEMANAGER_HEAPSIZE=308



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
	echo "Copying Hadoop $HADOOP_VERSION to all hosts..."
	pdcp -w ^all_hosts hadoop-"$HADOOP_VERSION".tar.gz /opt
    pdcp -w ^all_hosts zookeeper-"$ZOOKEEPER_VERSION".tar.gz /opt
if [ -z "$JAVA_HOME" ]; then
	echo "Copying JDK 1.8.0_92 to all hosts..."
	pdcp -w ^all_hosts jdk-8u92-linux-x64.rpm /opt

	echo "Installing JDK 1.8.0_92 on all hosts..."
	pdsh -w ^all_hosts chmod a+x /opt/jdk-8u92-linux-x64.rpm
	#pdsh -w ^all_hosts /opt/jdk-8u92-linux-x64.rpm -noregister 1>&- 2>&-
	pdsh -w ^all_hosts rpm -ivh /opt/jdk-8u92-linux-x64.rpm 1>&- 2>&-
	JAVA_HOME=/usr/java/jdk1.8.0_92
	echo "JAVA_HOME=$JAVA_HOME"
fi
	echo "Setting JAVA_HOME and HADOOP_HOME environment variables on all hosts..."
	
	echo "JAVA_HOME=$JAVA_HOME > /etc/profile.d/java.sh"
	pdsh -w ^all_hosts "echo export JAVA_HOME=$JAVA_HOME > /etc/profile.d/java.sh"
	pdsh -w ^all_hosts "source /etc/profile.d/java.sh"
    
	pdsh -w ^all_hosts "echo export HADOOP_HOME=$HADOOP_HOME > /etc/profile.d/hadoop.sh"
	pdsh -w ^all_hosts 'echo export HADOOP_PREFIX=$HADOOP_HOME >> /etc/profile.d/hadoop.sh'
    pdsh -w ^all_hosts 'echo export HADOOP_CONF_DIR=$HADOOP_CONF_DIR >> /etc/profile.d/hadoop.sh'
    
    
	pdsh -w ^all_hosts "source /etc/profile.d/hadoop.sh"
    
	pdsh -w ^zk_hosts "echo export ZOOKEEPER_HOME=$ZOOKEEPER_HOME > /etc/profile.d/zookeeper.sh"
	pdsh -w ^zk_hosts 'echo export ZOOKEEPER_PREFIX=$ZOOKEEPER_HOME >> /etc/profile.d/zookeeper.sh'
	pdsh -w ^zk_hosts 'echo export ZOOKEEPER_LOG_DIR=$ZOOKEEPER_HOME/logs >> /etc/profile.d/zookeeper.sh'
	pdsh -w ^zk_hosts 'echo export ZOO_LOG_DIR=$ZOOKEEPER_HOME/logs >> /etc/profile.d/zookeeper.sh'
	pdsh -w ^zk_hosts "source /etc/profile.d/zookeeper.sh"
    
    
	
    echo "Extracting Hadoop $HADOOP_VERSION distribution on all hosts..."
	pdsh -w ^all_hosts tar -zxf /opt/hadoop-"$HADOOP_VERSION".tar.gz -C /opt

    echo "Extracting Zookeeper $ZOOKEEPER_VERSION distribution on all ZK hosts..."
	pdsh -w ^all_hosts tar -zxf /opt/zookeeper-"$ZOOKEEPER_VERSION".tar.gz -C /opt

	echo "Creating system accounts and groups on all hosts..."
	pdsh -w ^all_hosts groupadd hadoop
	pdsh -w ^all_hosts useradd -g hadoop yarn
	pdsh -w ^all_hosts useradd -g hadoop hdfs
	pdsh -w ^all_hosts useradd -g hadoop mapred

	echo "Creating HDFS data directories on NameNode host, JournalNode hosts, Secondary NameNode host, and DataNode hosts..."
    pdsh -w ^all_hosts "mkdir -p $NN_DATA_DIR && chown hdfs:hadoop $NN_DATA_DIR"
    pdsh -w ^all_hosts "mkdir -p $NN_DATA_DIR && chown hdfs:hadoop $NN_DATA_DIR"
	pdsh -w ^all_hosts "mkdir -p $DN_DATA_DIR && chown hdfs:hadoop $DN_DATA_DIR"
    pdsh -w ^all_hosts "mkdir -p $JN_EDITS_DIR && chown hdfs:hadoop $JN_EDITS_DIR"
    pdsh -w ^all_hosts "mkdir -p $ZOOKEEPER_DATA_DIR && chown hdfs:hadoop $ZOOKEEPER_DATA_DIR"
    
    

	echo "Creating log directories on all hosts..."
	pdsh -w ^all_hosts "mkdir -p $YARN_LOG_DIR && chown yarn:hadoop $YARN_LOG_DIR"
	pdsh -w ^all_hosts "mkdir -p $HADOOP_LOG_DIR && chown hdfs:hadoop $HADOOP_LOG_DIR"
	pdsh -w ^all_hosts "mkdir -p $HADOOP_MAPRED_LOG_DIR && chown mapred:hadoop $HADOOP_MAPRED_LOG_DIR"
    pdsh -w ^all_hosts "mkdir -p $ZOOKEEPER_LOG_DIR && chown hdfs:hadoop $ZOOKEEPER_LOG_DIR"
    

	echo "Creating pid directories on all hosts..."
	pdsh -w ^all_hosts "mkdir -p $YARN_PID_DIR && chown yarn:hadoop $YARN_PID_DIR"
	pdsh -w ^all_hosts "mkdir -p $HADOOP_PID_DIR && chown hdfs:hadoop $HADOOP_PID_DIR"
	pdsh -w ^all_hosts "mkdir -p $HADOOP_MAPRED_PID_DIR && chown mapred:hadoop $HADOOP_MAPRED_PID_DIR"
    ##TODO JK PID는 어떻게 ? 어디에 ? 구글링해봐야...

	echo "Editing Hadoop environment scripts for log directories on all hosts..."
	pdsh -w ^all_hosts echo "export HADOOP_LOG_DIR=$HADOOP_LOG_DIR >> $HADOOP_HOME/etc/hadoop/hadoop-env.sh"
	pdsh -w ^all_hosts echo "export YARN_LOG_DIR=$YARN_LOG_DIR >> $HADOOP_HOME/etc/hadoop/yarn-env.sh"
	pdsh -w ^all_hosts echo "export HADOOP_MAPRED_LOG_DIR=$HADOOP_MAPRED_LOG_DIR >> $HADOOP_HOME/etc/hadoop/mapred-env.sh"

	echo "Editing Hadoop environment scripts for pid directories on all hosts..."
	pdsh -w ^all_hosts echo "export HADOOP_PID_DIR=$HADOOP_PID_DIR >> $HADOOP_HOME/etc/hadoop/hadoop-env.sh"
	pdsh -w ^all_hosts echo "export YARN_PID_DIR=$YARN_PID_DIR >> $HADOOP_HOME/etc/hadoop/yarn-env.sh"
	pdsh -w ^all_hosts echo "export HADOOP_MAPRED_PID_DIR=$HADOOP_MAPRED_PID_DIR >> $HADOOP_HOME/etc/hadoop/mapred-env.sh"
    ### ZK  PID관리는 어떻게.....
    

	if [ -n "$YARN_NODEMANAGER_HEAPSIZE" ]
	then 
		echo "for VM Memory Management  by warmpark   Editing Hadoop yarn-env.sh environment for YARN_NODEMANAGER_HEAPSIZE on all hosts..."
		pdsh -w ^all_hosts echo "export YARN_NODEMANAGER_HEAPSIZE=$YARN_NODEMANAGER_HEAPSIZE >> $HADOOP_HOME/etc/hadoop/yarn-env.sh"
	fi
    
    echo "Editing zookeeper conf zoo.cfg - 나중에 보완할 필요...."
    pdsh -w ^all_hosts "echo     'dataDir=$ZOOKEEPER_HOME/data
    dataLogDir=$ZOOKEEPER_HOME/logs
    clientPort=2181
    initLimit=5
    syncLimit=2
    server.1=big01:2888:3888
    server.2=big02:2888:3888
    server.3=big03:2888:3888' >  $ZOOKEEPER_HOME/conf/zoo.cfg"

    
    echo "Make zookeeper id in  $ZOOKEEPER_HOME/data/myid - 나중에 보완할 필요...."
    pdsh -w big01 "echo 1 > $ZOOKEEPER_HOME/data/myid"
    pdsh -w big02 "echo 2 > $ZOOKEEPER_HOME/data/myid"
    pdsh -w big03 "echo 3 > $ZOOKEEPER_HOME/data/myid"
    
    
    
   
    

	echo "Creating base Hadoop XML config files..."
	create_config --file core-site.xml
    put_config --file core-site.xml --property fs.defaultFS --value "hdfs://$DFS_NAMESERVICES"
    #put_config --file core-site.xml --property ha.zookeeper.quorum --value "$HA_ZOOKEEPER_QUORUM"
    put_config --file core-site.xml --property dfs.journalnode.edits.dir --value "$JN_EDITS_DIR"
    put_config --file core-site.xml --property hadoop.http.staticuser.user --value "$HTTP_STATIC_USER"


    create_config --file hdfs-site.xml
    put_config --file hdfs-site.xml --property dfs.nameservices --value "$DFS_NAMESERVICES"
    put_config --file hdfs-site.xml --property dfs.ha.namenodes."$DFS_NAMESERVICES" --value "nn1,nn2"
    put_config --file hdfs-site.xml --property dfs.namenode.rpc-address."$DFS_NAMESERVICES".nn1 --value "$nn:8020"
    put_config --file hdfs-site.xml --property dfs.namenode.rpc-address."$DFS_NAMESERVICES".nn2 --value "$snn:8020"
    put_config --file hdfs-site.xml --property dfs.namenode.http-address."$DFS_NAMESERVICES".nn1 --value "$nn:50070"
    put_config --file hdfs-site.xml --property dfs.namenode.http-address."$DFS_NAMESERVICES".nn2 --value "$snn:50070"
    put_config --file hdfs-site.xml --property dfs.namenode.shared.edits.dir --value "$NAMENODE_SHARED_EDITS_DIR"
    # put_config --file hdfs-site.xml --property dfs.ha.automatic-failover.enabled --value true
    put_config --file hdfs-site.xml --property dfs.client.failover.proxy.provider."$DFS_NAMESERVICES" --value "org.apache.hadoop.hdfs.server.namenode.ha.ConfiguredFailoverProxyProvider"
    put_config --file hdfs-site.xml --property dfs.ha.fencing.methods --value "sshfence"
    put_config --file hdfs-site.xml --property dfs.ha.fencing.ssh.private-key-files --value "/root/.ssh/id_rsa"

    put_config --file hdfs-site.xml --property dfs.namenode.name.dir --value "$NN_DATA_DIR"
    put_config --file hdfs-site.xml --property dfs.datanode.data.dir --value "$DN_DATA_DIR"
    

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
	

	echo "Copying base Hadoop XML config files to all hosts..."
	pdcp -w ^all_hosts core-site.xml hdfs-site.xml mapred-site.xml yarn-site.xml $HADOOP_HOME/etc/hadoop/
    
    echo "Copying the slaves file on each all hosts, in $HADOOP_CONF_DIR .... "
	#pdcp -w ^all_hosts  dn_hosts $HADOOP_HOME/etc/hadoop/slaves
    #pdcp -w ^all_hosts  jn_hosts $HADOOP_HOME/etc/hadoop/journalnodes
    
    

	echo "Creating configuration, command, and script links on all hosts..."
	pdsh -w ^all_hosts "ln -s $HADOOP_HOME/etc/hadoop /etc/hadoop"
	pdsh -w ^all_hosts "ln -s $HADOOP_HOME/bin/* /usr/bin"
	pdsh -w ^all_hosts "ln -s $HADOOP_HOME/libexec/* /usr/libexec"
    pdsh -w ^all_hosts "ln -s $ZOOKEEPER_HOME/conf/* /etc/zookeeper"
	#pdsh -w ^all_hosts "ln -s $ZOOKEEPER_HOME/bin/* /usr/bin"

    echo "Copying startup scripts to all hosts..."
	pdcp -w ^all_hosts hadoop-namenode /etc/init.d/
	pdcp -w ^all_hosts hadoop-secondarynamenode /etc/init.d/
	pdcp -w ^all_hosts hadoop-datanode /etc/init.d/
	pdcp -w ^all_hosts hadoop-resourcemanager /etc/init.d/
	pdcp -w ^all_hosts hadoop-nodemanager /etc/init.d/
	pdcp -w ^all_hosts hadoop-historyserver /etc/init.d/
	pdcp -w ^all_hosts hadoop-proxyserver /etc/init.d/
    pdcp -w ^all_hosts hadoop-zookeeper /etc/init.d/
    

    ## 데몬  PID을 위해 찾는 곳. ... - 
    pdsh -w ^all_hosts mkdir -p /var/run/hadoop
    pdsh -w ^all_hosts chmod 775 -R /var/run/hadoop
    pdsh -w ^all_hosts chown -R hdfs:hadoop /var/run/hadoop
    
  
    #1. ZK Quarum Daemon 실행
    #pdsh -w ^zk_hosts "su - hdfs -c '$ZOOKEEPER_HOME/bin/zkServer.sh start'"

    #2. ZK 내에 NameNode (Active & Standby) 이중화 관련 디렉토리 정리. - 반드시 ZK 가 실행 중이어야 함.
    #su - hdfs -c '$HADOOP_HOME/bin/hdfs zkfc -formatZK'
    #pdsh -w ^jn_hosts "su - hdfs -c '$HADOOP_HOME/bin/hdfs zkfc -formatZK'"

    #3. JournalNode 실행 . : hadoop-daemons.sh start journalnode
    pdsh -w ^jn_hosts "su - hdfs -c '$HADOOP_HOME/sbin/hadoop-daemon.sh start journalnode'"

    #4. Active Name Node  포멧 ( 저널노드가 실행되고 있어야 함. ) : hdfs namenode -format
    su - hdfs -c '$HADOOP_HOME/bin/hdfs namenode -format'
    #pdsh -w ^nn_host "su - hdfs -c '$HADOOP_HOME/bin/hdfs namenode -format'"

    #5. DataNode Daemon 실행 ( --config /opt/hadoop-2.7.2/etc/hadoop)
    pdsh -w ^dn_hosts "su - hdfs -c '$HADOOP_HOME/sbin/hadoop-daemon.sh  start datanode'"

    #5. NameNode Daemon 실행 (Active & Standby)  --> 네임노드는 반드시... root로 뛰워야 하나... 왜 hdfs로 안뜨는 거지.. ....
    pdsh -w ^jn_hosts "su - hdfs -c '$HADOOP_HOME/sbin/hadoop-daemon.sh start namenode'"

    #6. ZK Failover Controller Daemon 수행 -
    #pdsh -w ^jn_hosts "su - hdfs -c '$HADOOP_HOME/sbin/hadoop-daemon.sh start zkfc'"

    #7. Active Name Node의 filesystem 데이터를 Stand-by Name Node로 복사. (Stand-by Name Node에서 수행.) : hdfs namenode -bootstrapStandby
    pdsh -w ^snn_host "su - hdfs -c '$HADOOP_HOME/bin/hdfs namenode -bootstrapStandby'"

    #8. Name Node의 데이터를 Journal Node에 초기화 (Stan-by Name Node에서 실행) : hdfs namenode -initializeSharedEdits
    pdsh -w ^snn_host "su - hdfs -c '$HADOOP_HOME/bin/hdfs namenode -initializeSharedEdits'"

    ## 이하   yarn
    #9. start resource manager : pdsh -w ^rm_host ${HADOOP_HOME}/sbin/yarn-daemon.sh --config /opt/hadoop-2.7.2/etc/hadoop start resourcemanager
       pdsh -w ^rm_host "su - yarn -c '${HADOOP_HOME}/sbin/yarn-daemon.sh --config /opt/hadoop-2.7.2/etc/hadoop start resourcemanager'"
    #10. start nodemanagers.  ( 왜 3번은 안 뜨지......)
     pdsh -w ^nm_hosts "su - yarn -c '${HADOOP_HOME}/sbin/yarn-daemon.sh  start nodemanager'"

    #11. start proxy server
    pdsh -w ^yarn_proxy_host "su - yarn -c '${HADOOP_HOME}/sbin/yarn-daemon.sh start proxyserver'"

    # 12. start history server
     pdsh -w ^mr_history_host "su - mapred -c '${HADOOP_HOME}/sbin/mr-jobhistory-daemon.sh  start historyserver'"
    
    
    #pdsh -w ^nn_host "su - hdfs -c '$HADOOP_HOME/sbin/start-dfs.sh'"
    #pdsh -w ^nn_host "su - yarn -c '$HADOOP_HOME/sbin/start-yarn.sh'"
    

    
	#echo "Starting Hadoop $HADOOP_VERSION services on all hosts... 잠시 중지...."
    #pdsh -w ^dn_hosts "chmod 755 /etc/init.d/hadoop-datanode && chkconfig hadoop-datanode on && service hadoop-datanode start"
	#pdsh -w ^nn_host "chmod 755 /etc/init.d/hadoop-namenode && chkconfig hadoop-namenode on && service hadoop-namenode start"
	#pdsh -w ^snn_host "chmod 755 /etc/init.d/hadoop-namenode && chkconfig hadoop-namenode on && service hadoop-namenode start"
	#pdsh -w ^dn_hosts "chmod 755 /etc/init.d/hadoop-datanode && chkconfig hadoop-datanode on && service hadoop-datanode start"
	#pdsh -w ^rm_host "chmod 755 /etc/init.d/hadoop-resourcemanager && chkconfig hadoop-resourcemanager on && service hadoop-resourcemanager start"
	#pdsh -w ^nm_hosts "chmod 755 /etc/init.d/hadoop-nodemanager && chkconfig hadoop-nodemanager on && service hadoop-nodemanager start"
	#pdsh -w ^yarn_proxy_host "chmod 755 /etc/init.d/hadoop-proxyserver && chkconfig hadoop-proxyserver on && service hadoop-proxyserver start"
    
   
	#echo "Creating MapReduce Job History directories..."
	#su - hdfs -c "hdfs dfs -mkdir -p /mapred/history/done_intermediate"
	#su - hdfs -c "hdfs dfs -chown -R mapred:hadoop /mapred"
	#su - hdfs -c "hdfs dfs -chmod -R g+rwx /mapred"

	#pdsh -w ^mr_history_host "chmod 755 /etc/init.d/hadoop-historyserver && chkconfig hadoop-historyserver on && service hadoop-historyserver start"

	#echo "Running YARN smoke test..."
	#pdsh -w ^all_hosts "usermod -a -G hadoop $(whoami)"
	#su - hdfs -c "hadoop fs -mkdir -p /user/$(whoami)"
	#su - hdfs -c "hadoop fs -chown $(whoami):$(whoami) /user/$(whoami)"
	#source /etc/profile.d/java.sh
	#source /etc/profile.d/hadoop.sh
	#source /etc/hadoop/hadoop-env.sh
	#source /etc/hadoop/yarn-env.sh
	#hadoop jar $HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-examples-$HADOOP_VERSION.jar pi -Dmapreduce.clientfactory.class.name=org.apache.hadoop.mapred.YarnClientFactory -libjars $HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-client-jobclient-$HADOOP_VERSION.jar 16 10000
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

