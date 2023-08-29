# Settings
root=/home/$USER
archives_dir=$root/archives
deploy_dir=$root/deploy
conf_dir=$root/pseudo_distr/confs
nodefile=$OAR_NODEFILE

ssh-keygen -f "/home/lruellou/.ssh/known_hosts" -R "localhost"

echo "Download dependencies"
sudo-g5k apt-get install ssh
sudo-g5k apt-get install pdsh
sudo-g5k apt-get -y install pssh

sudo-g5k ln -f /usr/bin/parallel-ssh /usr/local/bin/pssh
sudo-g5k ln -f /usr/bin/parallel-scp /usr/local/bin/pscp
sudo-g5k ln -f /usr/bin/parallel-rsync /usr/local/bin/prsync
export PATH=$PATH:/usr/lib

echo -e "\nExtracting archives (hadoop, spark, java, tpcx-ai) if needed"
if [ ! -d $deploy_dir/hadoop-3.3.2 ]; then
    tar -zxf "$archives_dir/hadoop-3.3.2.tar.gz" -C $deploy_dir
fi
if [ ! -d $deploy_dir/spark-2.4.8 ]; then
    tar -zxf "$archives_dir/spark-2.4.8.tgz" -C $deploy_dir
fi
if [ ! -d $deploy_dir/jre1.8.0_371 ]; then
    tar -zxf "$archives_dir/java8jdk.tar.gz" -C $deploy_dir
fi
if [ ! -d $deploy_dir/Python-3.7.17 ]; then
	echo -e "\nInstalling python 3.7"
	tar -zxf "$archives_dir/Python-3.7.17.tgz" -C $deploy_dir
	cd $deploy_dir/Python-3.7.17/
	./configure > /dev/null
	make > /dev/null
	sudo-g5k make install -C $deploy_dir/Python-3.7.17 -j8 > /dev/null
	sudo-g5k update-alternatives --install /usr/bin/python python /usr/local/bin/python3.7 1
fi

echo -e "\nSetting environment variables"
export JAVA_HOME="$deploy_dir/jre1.8.0_371"
export HADOOP_HOME="$deploy_dir/hadoop-3.3.2"
export SPARK_HOME="$deploy_dir/spark-2.4.8"
export SPARK_LOCAL_IP=localhost
export SPARK_DIST_CLASSPATH=$($HADOOP_HOME/bin/hadoop classpath)
export PYSPARK_PYTHON=/usr/bin/python3
export PYTHONPATH=$(ZIPS=("$SPARK_HOME"/python/lib/*.zip); IFS=:; echo "${ZIPS[*]}"):$PYTHONPATH
export PATH=$JAVA_HOME/bin:$HADOOP_HOME/bin:$SPARK_HOME/bin:$PATH
export PDSH_RCMD_TYPE=ssh

echo -e "\nDeploying configuration files"
echo "export JAVA_HOME=$JAVA_HOME" >> $HADOOP_HOME/etc/hadoop/hadoop-env.sh
cp $conf_dir/hadoop/* $HADOOP_HOME/etc/hadoop/

echo -e "\nCleaning hdfs directory"
rm -Rf /mnt/disk1/tmp/*

echo -e "\nStarting nodes and preparing hdfs directories"
hdfs namenode -format > /dev/null
$HADOOP_HOME/sbin/start-dfs.sh
$HADOOP_HOME/sbin/start-yarn.sh