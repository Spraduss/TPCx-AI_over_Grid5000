echo -e "\nDeploying tpcx-ai configuration files"
tpcxai_home=/home/$USER/deploy/tpcx-ai-v1.0.2
current_dir=/home/$USER/pseudo_distr/confs/tpcxai

cp $current_dir/setenv.sh $tpcxai_home/setenv.sh
cp $current_dir/spark.yaml $tpcxai_home/driver/config/spark.yaml
cp $current_dir/tpcxai-generation.xml $tpcxai_home/lib/pdgf/config/tpcxai-generation.xml
cp $current_dir/getEnvInfo.sh $tpcxai_home/tools/spark/getEnvInfo.sh
cp $current_dir/python.yaml $tpcxai_home/tools/spark/python.yaml
#cp $current_dir/default.yaml $tpcxai_home/driver/config/default.yaml
