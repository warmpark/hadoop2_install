#!/bin/bash
# Install Hadoop 2 using pdsh/pdcp where possible.
# 
# Command can be interactive or file-based.  This script sets up
# a Hadoop 2 cluster with basic configuration.  Modify data, log, and pid
# directories as desired.  Further configure your cluster with ./conf-hadoop2.sh
# after running this installation script.
#

. $(dirname "$0")/stop-hadoop2-ha.sh

#pdsh -w ^dn_hosts "service hadoop-datanode stop"
#pdsh -w ^nn_host "service hadoop-namenode stop"
#pdsh -w ^snn_host "service hadoop-namenode stop"
#pdsh -w ^mr_history_host "service hadoop-historyserver stop"
#pdsh -w ^yarn_proxy_host "service hadoop-proxyserver stop"
#pdsh -w ^nm_hosts "service hadoop-nodemanager stop"
#pdsh -w ^rm_host "service hadoop-resourcemanager stop"



echo "Removing hbase & PHOENIX distribution tarball..."
pdsh -w ^all_hosts "rm -r /opt/apache-phoenix-${PHOENIX_VERSION}-HBase-${PHOENIX_HBASE_VERSION}-bin.tar.gz"
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

echo "Removing ZEPPELIN distribution tarball..."
pdsh -w ^all_hosts "rm -r /opt/zeppelin-${ZEPPELIN_VERSION}-bin-all.tgz"




# JAVA_HOME = "" 이면 자바삭제.
JAVA_HOME="-"

echo "Removing Hadoop 2 startup scripts..."
pdsh -w ^all_hosts "rm -f /etc/init.d/hadoop-*"


#JDK삭제 하지 않기 위해 주석 처리함 삭제시 주석 해제
 if [ -z "$JAVA_HOME" ]; then
	#JDK rpm java 삭제 하지 않기 위해 주석 처리함 삭제시 주석 해제
	echo "Uninstalling JDK ${JDK_VERSION} RPM..."
	pdsh -w ^all_hosts "rpm -ev jdk${JDK_VERSION}"
	#JDK rpm 삭제 하지 않기 위해 주석 처리함 삭제시 주석 해제
	
	echo "Removing JDK ${JDK_VERSION} distribution..."
	pdsh -w ^all_hosts "rm -f /opt/jdk*"
	echo "Removing JDK ${JDK_VERSION} artifacts..."
	pdsh -w ^all_hosts "rm -f sun-java*"
	pdsh -w ^all_hosts "rm -f jdk*"
fi
#JDK삭제 하지 않기 위해 주석 처리함 삭제시 주석 해제

echo "Removing Java bash environment setting..."
pdsh -w ^all_hosts "rm -f /etc/profile.d/java.sh"
echo "Removing Hadoop 2 bash environment setting..."
pdsh -w ^all_hosts "rm -f /etc/profile.d/hadoop.sh"
echo "Removing Zookeeper bash environment setting..."
pdsh -w ^zk_hosts "rm -f /etc/profile.d/zookeeper.sh"
echo "Removing hbase bash environment setting..."
pdsh -w ^all_hosts "rm -f /etc/profile.d/hbase.sh"

echo "Removing Kafka bash environment setting..."
pdsh -w ^all_hosts "rm -f /etc/profile.d/kafka.sh"
echo "Removing Storm bash environment setting..."
pdsh -w ^all_hosts "rm -f /etc/profile.d/storm.sh"
echo "Removing NiFi bash environment setting..."
pdsh -w ^all_hosts "rm -f /etc/profile.d/nifi.sh"
echo "Removing ZEPPELIN bash environment setting..."
pdsh -w ^all_hosts "rm -f /etc/profile.d/zeppelin.sh"


echo "Removing /etc/hadoop, zookeeper, hbase link..."
pdsh -w ^all_hosts "rm -rf /etc/hadoop"
pdsh -w ^all_hosts "rm -rf /etc/zookeeper"
pdsh -w ^all_hosts "rm -rf /etc/hbase"

pdsh -w ^all_hosts "rm -rf /etc/kafka"
pdsh -w ^all_hosts "rm -rf /etc/storm"
pdsh -w ^all_hosts "rm -rf /etc/nifi"
pdsh -w ^all_hosts "rm -rf /etc/zeppelin"


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

pdsh -w ^all_hosts "rm /usr/bin/*kafka*"
pdsh -w ^all_hosts "rm /usr/bin/*storm*"
pdsh -w ^all_hosts "rm /usr/bin/*nifi*"
pdsh -w ^all_hosts "rm /usr/bin/*zeppelin*"


echo "Removing Hadoop 2 script links..."
pdsh -w ^all_hosts "rm /usr/libexec/hadoop-config.*"
pdsh -w ^all_hosts "rm /usr/libexec/hdfs-config.*"
pdsh -w ^all_hosts "rm /usr/libexec/httpfs-config.*"
pdsh -w ^all_hosts "rm /usr/libexec/mapred-config.*"
pdsh -w ^all_hosts "rm /usr/libexec/yarn-config.*"
pdsh -w ^all_hosts "rm /usr/libexec/kms-config.*"

echo "Removing directory..."
pdsh -w ^all_hosts "rm -rf $NN_DATA_DIR"
pdsh -w ^all_hosts "rm -rf $DN_DATA_DIR"
pdsh -w ^all_hosts "rm -rf $JN_EDITS_DIR"
pdsh -w ^all_hosts "rm -rf $ZOOKEEPER_DATA_DIR"
pdsh -w ^all_hosts "rm -rf $HBASE_DATA_DIR"
pdsh -w ^all_hosts "rm -rf $KAFKA_DATA_DIR"
pdsh -w ^all_hosts "rm -rf $STORM_DATA_DIR"
pdsh -w ^all_hosts "rm -rf $NIFI_DATA_DIR"
pdsh -w ^all_hosts "rm -rf $ZEPPELIN_DATA_DIR"

pdsh -w ^all_hosts "rm -rf $YARN_LOG_DIR"
pdsh -w ^all_hosts "rm -rf $HADOOP_LOG_DIR"
pdsh -w ^all_hosts "rm -rf $HADOOP_MAPRED_LOG_DIR"
pdsh -w ^all_hosts "rm -rf $ZOOKEEPER_LOG_DIR"
pdsh -w ^all_hosts "rm -rf $HBASE_LOG_DIR"
pdsh -w ^all_hosts "rm -rf $KAFKA_LOG_DIR"
pdsh -w ^all_hosts "rm -rf $STORM_LOG_DIR"
pdsh -w ^all_hosts "rm -rf $NIFI_LOG_DIR"
pdsh -w ^all_hosts "rm -rf $ZEPPELIN_LOG_DIR"

pdsh -w ^all_hosts "rm -rf $YARN_PID_DIR"
pdsh -w ^all_hosts "rm -rf $HADOOP_PID_DIR"
pdsh -w ^all_hosts "rm -rf $HADOOP_MAPRED_PID_DIR"
pdsh -w ^all_hosts "rm -rf $HBASE_PID_DIR"
pdsh -w ^all_hosts "rm -rf $KAFKA_PID_DIR"
pdsh -w ^all_hosts "rm -rf $STORM_PID_DIR"
pdsh -w ^all_hosts "rm -rf $NIFI_PID_DIR"
pdsh -w ^all_hosts "rm -rf $ZEPPELIN_PID_DIR"

pdsh -w ^all_hosts "rm -rf $ZOOKEEPER_CONF_DIR"
pdsh -w ^all_hosts "rm -rf $HADOOP_CONF_DIR"
pdsh -w ^all_hosts "rm -rf $HBASE_CONF_DIR"
pdsh -w ^all_hosts "rm -rf $KAFKA_CONF_DIR"
pdsh -w ^all_hosts "rm -rf $STORM_CONF_DIR"
pdsh -w ^all_hosts "rm -rf $NIFI_CONF_DIR"
pdsh -w ^all_hosts "rm -rf $ZEPPELIN_CONF_DIR"


pdsh -w ^all_hosts "rm -rf /var/data/hadoop"
pdsh -w ^all_hosts "rm -rf /var/log/hadoop"
pdsh -w ^all_hosts "rm -rf /var/run/hadoop"


pdsh -w ^all_hosts "rm -rf $HADOOP_HOME"
pdsh -w ^all_hosts "rm -rf $ZOOKEEPER_HOME"
pdsh -w ^all_hosts "rm -rf $HBASE_HOME"
pdsh -w ^all_hosts "rm -rf $PHOENIX_HOME"

pdsh -w ^all_hosts "rm -rf $KAFKA_HOME"
pdsh -w ^all_hosts "rm -rf $STORM_HOME"
pdsh -w ^all_hosts "rm -rf $NIFI_HOME"
pdsh -w ^all_hosts "rm -rf $ZEPPELIN_HOME"

## JPS 가지지 삭제 -- 프로세스를 죽이는 건 아님
pdsh -w ^all_hosts "rm -rf /tmp/hsperfdata_*"

echo "Removing zeppelin system account..."
pdsh -w ^all_hosts "userdel -rf zeppelin"

echo "Removing nifi system account..."
pdsh -w ^all_hosts "userdel -rf nifi"

echo "Removing storm system account..."
pdsh -w ^all_hosts "userdel -rf storm"

echo "Removing kafka system account..."
pdsh -w ^all_hosts "userdel -rf kafka"

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


pdsh -w ^all_hosts "rm -rf /tmp/hsperfdata_*"
