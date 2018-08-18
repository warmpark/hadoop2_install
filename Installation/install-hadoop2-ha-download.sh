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
  ## JDK DOWNLOAD
	if [ ! -e "$JDK_RPM_NAME" ]; then
		echo "JDK PRM File does not exist"
		wget --no-cookies --no-check-certificate --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" ${JDK_DOWNLOAD_URI}
		#wget --no-cookies --no-check-certificate --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" "http://download.oracle.com/otn-pub/java/jdk/8u131-b11/d54c1d3a095b4ff2b6607d096fa80163/jdk-8u131-linux-x64.rpm"

	else 
		echo "JDK PRM File exists"
	fi

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

	## ZEPPELIN DOWNLOAD
    zeppelinfile=./zeppelin-${ZEPPELIN_VERSION}-bin-all.tgz
    if [ ! -e "$zeppelinfile" ]; then
        echo "File does not exist"
        wget ${ZEPPELIN_DOWNLOAD_URI}
    else 
        echo "ZEPPELIN File exists"
    fi
    		
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
