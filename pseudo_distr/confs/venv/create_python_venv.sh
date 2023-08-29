pip install virtualenv > /dev/null
python3 -m virtualenv ./venv-test > /dev/null
source ./venv-test/bin/activate > /dev/null
python3 -m pip install -r ./requirement.txt > /dev/null
python3 -m pip install -e /home/$USER/deploy/tpcx-ai-v1.0.2/workload/spark/pyspark > /dev/null
python3 -m pip install -e /home/$USER/deploy/tpcx-ai-v1.0.2/driver > /dev/null
