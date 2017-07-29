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

pdsh -w ^all_hosts "source /etc/profile.d/java.sh"
pdsh -w ^all_hosts "source /etc/profile.d/hadoop.sh"
pdsh -w ^zk_hosts  "source /etc/profile.d/zookeeper.sh"
pdsh -w ^all_hosts "source /etc/profile.d/hbase.sh"

pdsh -w ^all_hosts "source $HADOOP_CONF_DIR/hadoop-env.sh"	
pdsh -w ^all_hosts "source $HADOOP_CONF_DIR/yarn-env.sh"
pdsh -w ^all_hosts "source $HADOOP_CONF_DIR/mapred-env.sh"
pdsh -w ^all_hosts "source $HBASE_CONF_DIR/hbase-env.sh"


pdsh -w ^all_hosts "su - hdfs -c /opt/kafka_2.10-0.10.1.1/bin/kafka-server-stop.sh"

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


echo "Removing nifi distribution tarball..."
pdsh -w ^all_hosts "rm -r /opt/nifi-${NIFI_VERSION}-bin.tar.gz"

echo "Removing storm distribution tarball..."
pdsh -w ^all_hosts "rm -r /opt/apache-storm-${STORM_VERSION}.tar.gz"

echo "Removing kafka distribution tarball..."
pdsh -w ^all_hosts "rm -r /opt/kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz"




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

