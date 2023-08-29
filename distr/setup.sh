if [ $# -ne 2 ]; then
	echo "First parameter is number of loops, second is directory name"
	exit 1
fi

nodefile="$OAR_NODEFILE" # file with requested nodes
root="/home/$USER/distr"
deploy_dir="$root/deploy"
archiv_dir="/home/$USER/archives"
venv_conf="/home/${USER}/distr/venv"
benchmark="$archiv_dir/tpcx-ai.tar.gz"
workersfile="$root/confs/conf-distr-mode-hadoop3/workers"

echo "cleaning yarndata dir"
for node in $(uniq $nodefile)
do
	ssh ${node} "rm -rf /tmp/yarndata"
done

echo "Installing pssh, pscp, prsync"
sudo-g5k apt-get -y install pssh
sudo-g5k ln -f /usr/bin/parallel-ssh /usr/local/bin/pssh
sudo-g5k ln -f /usr/bin/parallel-scp /usr/local/bin/pscp
sudo-g5k ln -f /usr/bin/parallel-rsync /usr/local/bin/prsync
sudo-g5k apt-get -y install sqlite3 libsqlite3-dev

uniq $nodefile | tail -n +2 >$workersfile
cp -fr $workersfile $root/confs/conf-distr-mode-spark24/slaves
cp -fr $workersfile $root/confs/conf-distr-mode-spark24/workers
uniq $nodefile > $deploy_dir/tpcx-ai/nodes

echo "Deploying benchmark locally"
tar -zxf $benchmark -C /tmp/
cp $deploy_dir/tpcx-ai/nodes /tmp/tpcx-ai/nodes
cp $deploy_dir/tpcx-ai/driver/config/spark.yaml /tmp/tpcx-ai/driver/config/
cp $deploy_dir/tpcx-ai/lib/pdgf/config/tpcxai-generation.xml /tmp/tpcx-ai/lib/pdgf/config/
cp $deploy_dir/tpcx-ai/driver/config/spark.yaml /tmp/tpcx-ai/driver/config/
sed -i s/namenode-g5k/$(uniq $OAR_NODEFILE | head -n 1)/g /tmp/tpcx-ai/driver/config/spark.yaml
cp $deploy_dir/tpcx-ai/tools/spark/getEnvInfo.sh /tmp/tpcx-ai/tools/spark/
cp $deploy_dir/tpcx-ai/tools/spark/python.yaml /tmp/tpcx-ai/tools/spark/
cp $deploy_dir/tpcx-ai/tools/parallel-data-load.sh /tmp/tpcx-ai/tools/

sed -i s/namenode-g5k/$(uniq $nodefile | head -n 1)/g /tmp/tpcx-ai/lib/pdgf/config/tpcxai-generation.xml

echo "Deploying benchmark on all nodes"
prsync -az -h $workersfile $benchmark /tmp/
pssh -h $workersfile "tar -xf /tmp/tpcx-ai.tar.gz -C /tmp/ && rm -f /tmp/tpcx-ai.tar.gz && sed -i s/namenode-g5k/$(uniq $nodefile | head -n 1)/g /tmp/tpcx-ai/lib/pdgf/config/tpcxai-generation.xml"

echo "Installing Python3.7"
tar -xf $archiv_dir/Python-3.7.17.tgz -C /tmp/ --overwrite > /dev/null 2> /dev/null
cd /tmp/Python-3.7.17/
/tmp/Python-3.7.17/configure > /dev/null
make -C /tmp/Python-3.7.17 -j8 > /dev/null
sudo-g5k make install -C /tmp/Python-3.7.17 > /dev/null 2>/dev/null
sudo-g5k ln -f /usr/local/bin/python3 /usr/local/bin/python # python symlink to python3 (python3.7)

echo "Deploying Python3.7 on all nodes"
prsync -az -h $workersfile /tmp/Python-3.7.17 /tmp/ > /dev/null
pssh -h $workersfile 'sudo-g5k make install -C /tmp/Python-3.7.17 -f /tmp/Python-3.7.17/Makefile; sudo-g5k ln -f /usr/local/bin/python3 /usr/local/bin/python' > /dev/null

echo "Installing Java 8 on all nodes"
sudo-g5k tar -xzf $archiv_dir/java8jdk.tar.gz -C /usr/lib/jvm --overwrite && sudo-g5k update-alternatives --install /usr/bin/java java /usr/lib/jvm/jre1.8.0_371/bin/java 1 && sudo-g5k update-alternatives --set java /usr/lib/jvm/jre1.8.0_371/bin/java
prsync -az -h $workersfile $archiv_dir/java8jdk.tar.gz /tmp/
pssh -h $workersfile sudo-g5k tar -xzf /tmp/java8jdk.tar.gz -C /usr/lib/jvm --overwrite
pssh -h $workersfile sudo-g5k update-alternatives --install /usr/bin/java java /usr/lib/jvm/jre1.8.0_371/bin/java 1
pssh -h $workersfile sudo-g5k update-alternatives --set java /usr/lib/jvm/jre1.8.0_371/bin/java

rm -rf $root/conf-distr-mode-hadoop3/ $root/config.log $root/config.status $root/Makefile $root/Makefile.pre $root/Misc/ $root/Modules/ $root/Objects/ $root/Parser/ $root/Programs/ $root/pyconfig.h $root/Python/ 2> /dev/null

echo "Building benchmark venv locally"
cd /tmp/tpcx-ai
rm -rf /tmp/tpcx-ai/lib/python-venv # removing previous virtual environment

python -m pip install virtualenv > /dev/null
python -m virtualenv /tmp/tpcx-ai/lib/python-venv > /dev/null
source /tmp/tpcx-ai/lib/python-venv/bin/activate > /dev/null
python3 -m ensurepip
python -m pip install -r $venv_conf/requirement.txt > /dev/null
python -m pip install -e /tmp/tpcx-ai/workload/python > /dev/null
python -m pip install -e /tmp/tpcx-ai/workload/spark/pyspark > /dev/null
python -m pip install -e /tmp/tpcx-ai/driver > /dev/null
deactivate

echo "Deploying benchmark venv on all nodes"
pssh -h $workersfile rm -rf /tmp/tpcx-ai/lib/python-venv
prsync -az -h $deploy_dir/tpcx-ai/nodes /tmp/tpcx-ai/lib/python-venv /tmp/tpcx-ai/lib/ > /dev/null

~/distr/exec-hadoop-deploy.sh distr hadoop3 -deploy
~/distr/exec-hadoop-deploy.sh distr hadoop3 -conf
~/distr/exec-spark-deploy.sh distr spark24 -deploy
~/distr/exec-spark-deploy.sh distr spark24 -conf

export PATH=$PATH:/tmp/hadoop/bin:/tmp/spark/bin
export PDSH_RCMD_TYPE=ssh

ssd=0
hdd=0
echo "Formatting, partitioning and mounting disks on all nodes"
for node in $(uniq $nodefile)
do
    disktype=$(ssh $node lsblk -dno ROTA /dev/sda) # setting prefix for HDFS data dirs
    if [ $disktype -eq 1 ]; then
        datadirs="[DISK]file:///tmp/yarndata/hadoop3/dfs/"
        hdd=1
    elif [ $disktype -eq 0 ]; then
        datadirs="[SSD]file:///tmp/yarndata/hadoop3/dfs/"
        ssd=1
    fi

    counter=1
    for disk in $(ssh $node "lsblk -do NAME | tail -n +3 | grep sd")
    do
	ssh $node "sudo-g5k wipefs /dev/${disk}"
        ssh $node "echo 'type=83' | sudo-g5k sfdisk /dev/${disk}"
        ssh $node "sudo-g5k mkfs.ext4 -m 0 /dev/${disk}1"
        ssh $node "mkdir -p /tmp/disk${counter} /tmp/yarndata/hadoop3/dfs${counter}"
        ssh $node "sudo-g5k mount /dev/${disk}1 /tmp/disk${counter}"
        ssh $node "sudo-g5k mount /dev/${disk}1 /tmp/yarndata/hadoop3/dfs${counter}"
        ssh $node "sudo-g5k chown ${USER} /tmp/yarndata/hadoop3/dfs${counter}"
        ssh $node "mkdir /tmp/yarndata/hadoop3/dfs${counter}/data"

        disktype=$(ssh $node lsblk -dno ROTA /dev/${disk}) # setting prefix for HDFS data dirs
        if [ $disktype -eq 1 ]; then
            datadirs="$datadirs,[DISK]file:///tmp/yarndata/hadoop3/dfs${counter}/"
            hdd=1
	    echo "HDD" >> ~/distr/disk.txt
        elif [ $disktype -eq 0 ]; then
            datadirs="$datadirs,[SSD]file:///tmp/yarndata/hadoop3/dfs${counter}/"
            ssd=1
	    echo "SSD" >> ~/distr/disk.txt
        fi

        ((counter++))
    done

    ssh $node sed -i s+datadirs-g5k+$datadirs+g /tmp/hadoop/etc/hadoop/hdfs-site.xml
    ssh $node sed -i s+datadirs-g5k+$(echo $datadirs | sed 's+\[DISK\]file://++g' | sed 's+\[SSD\]file://++g')+g /tmp/spark/conf/spark-env.sh

done

mkdir -p /tmp/yarndata/hadoop3/dfs/name

cp /tmp/hadoop/etc/hadoop/core-site.xml /tmp/spark/conf
cp /tmp/hadoop/etc/hadoop/hdfs-site.xml /tmp/spark/conf
cp /tmp/hadoop/etc/hadoop/yarn-site.xml /tmp/spark/conf

~/distr/exec-hadoop-deploy.sh distr hadoop3 -clearfs
~/distr/cluster-control.sh start yarn dfs spark

if [ $ssd -eq 1 ]; then
    if [ $hdd -eq 1 ]; then
        hdfs storagepolicies -setStoragePolicy -path /user/$USER -policy One_SSD
        hdfs storagepolicies -satisfyStoragePolicy -path /user/$USER
    else
        hdfs storagepolicies -setStoragePolicy -path /user/$USER -policy All_SSD
        hdfs storagepolicies -satisfyStoragePolicy -path /user/$USER
    fi
fi

sed -i s/number_of_workers/$(wc -l /tmp/spark/conf/slaves | awk '{ print $1 }')/g /tmp/tpcx-ai/driver/config/spark.yaml
rm -f /tmp/tpcx-ai/logs/tpcxai-metrics-*

source /tmp/tpcx-ai/setenv.sh
/tmp/tpcx-ai/tools/enable_parallel_datagen.sh

for ((i=1 ; i<=$1 ; i++))
do
	/tmp/tpcx-ai/bin/tpcxai.sh -uc 7 -c /tmp/tpcx-ai/driver/config/spark.yaml -sf 10
done

if [ ! -d ~/metrics/$2 ]; then
        mkdir -p ~/metrics/$2
fi
if [ ! -d ~/spark_logs/$2 ]; then
	mkdir -p ~/spark_logs/$2
fi
/tmp/hadoop/bin/hdfs dfs -copyToLocal /user/hadoop/spark/events/* ~/spark_logs/$2
cp /tmp/tpcx-ai/logs/tpcxai-metrics-* ~/metrics/$2

