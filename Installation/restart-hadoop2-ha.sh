#!/bin/bash

source /etc/profile.d/java.sh
source /etc/profile.d/hadoop.sh
source /etc/hadoop/hadoop-env.sh
source /etc/hadoop/yarn-env.sh
source /etc/hadoop/hbase-env.sh

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


 
echo "#1. Start ZK Quarum Daemon(su - hdfs -c '$ZOOKEEPER_HOME/bin/zkServer.sh start') :모든 ZK에서:  3,5 ... 홀수개수로 "
pdsh -w ^zk_hosts "su - hdfs -c '$ZOOKEEPER_HOME/bin/zkServer.sh start'"

#echo "#2. ZK 내에 NameNode 이중화 관련 ZK 정보 초기화(su - hdfs -c '$HADOOP_HOME/bin/hdfs zkfc -formatZK'):Active NameNode 후보에서만: 반드시 ZK 가 실행 중이어야 함"
#pdsh -w ^nn_host "su - hdfs -c '$HADOOP_HOME/bin/hdfs zkfc -formatZK'"

echo "#3. Start JournalNode Daemon(su - hdfs -c '$HADOOP_HOME/sbin/hadoop-daemon.sh start journalnode'):모든 JN에서: ZK Node와 동일하게 설치해야 하나? 그럴 필요 없어요 : 3,5 ... 홀수개"
pdsh -w ^jn_hosts "su - hdfs -c '$HADOOP_HOME/sbin/hadoop-daemon.sh start journalnode'"

#echo "#4. Active Name Node  포멧(su - hdfs -c '$HADOOP_HOME/bin/hdfs namenode -format'):Active NameNode 후보에서만: 저널노드가 실행되고 있어야 함"
#pdsh -w ^nn_host "su - hdfs -c '$HADOOP_HOME/bin/hdfs namenode -format'"

echo "#5. Start DataNode Daemon(su - hdfs -c '$HADOOP_HOME/sbin/hadoop-daemon.sh  start datanode'):모든 DN에서:"
pdsh -w ^dn_hosts "su - hdfs -c '$HADOOP_HOME/sbin/hadoop-daemon.sh  start datanode'"

echo "#6. Start Active NameNode Daemon(su - hdfs -c '$HADOOP_HOME/sbin/hadoop-daemon.sh start namenode')"
pdsh -w ^nn_host "su - hdfs -c '$HADOOP_HOME/sbin/hadoop-daemon.sh start namenode'"


echo "#7. Start ZK Failover Controller Daemon(su - hdfs -c '$HADOOP_HOME/sbin/hadoop-daemon.sh start zkfc'):각 Name Node 마다:Name Node와 ZKFC의 실행 순서는 중요하지 않음. "
pdsh -w ^nn_host "su - hdfs -c '$HADOOP_HOME/sbin/hadoop-daemon.sh start zkfc'"
pdsh -w ^snn_host "su - hdfs -c '$HADOOP_HOME/sbin/hadoop-daemon.sh start zkfc'"

echo "#8. Active Name Node의 filesystem 데이터를 Stand-by Name Node로 복사(su - hdfs -c '$HADOOP_HOME/bin/hdfs namenode -bootstrapStandby') :Stand-by Name Node에서만:"
pdsh -w ^snn_host "su - hdfs -c '$HADOOP_HOME/bin/hdfs namenode -bootstrapStandby'"


echo "#9. Start Stand-by NameNode Daemon(su - hdfs -c '$HADOOP_HOME/sbin/hadoop-daemon.sh start namenode') : Stand-by NN에서 : "
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

echo "#15. Start HBASE Server(su - hbase -c '$HBASE_HOME/bin/start-hbase.sh') "
pdsh -w ^nn_host "su - hdfs -c '$HBASE_HOME/bin/hbase-daemon.sh start master'"
pdsh -w ^hbase_regionservers "su - hdfs -c '$HBASE_HOME/bin/hbase-daemon.sh start regionserver'"

echo "#16. Running YARN smoke test..."
pdsh -w ^all_hosts "usermod -a -G hadoop $(whoami)"
su - hdfs -c "hadoop fs -mkdir -p /user/$(whoami)"
su - hdfs -c "hadoop fs -chown $(whoami):$(whoami) /user/$(whoami)"
#hadoop jar $HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-examples-$HADOOP_VERSION.jar pi -Dmapreduce.clientfactory.class.name=org.apache.hadoop.mapred.YarnClientFactory -libjars $HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-client-jobclient-$HADOOP_VERSION.jar 16 10000



