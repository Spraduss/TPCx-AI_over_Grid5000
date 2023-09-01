# TPCx-AI_over_Grid5000
Scripts and tools used during my internship at the DEECEI to launch the TPCx-AI benchmark over Grid'5000.

**For a correct use of this repository, once cloned, move every file/directory to the home of Grid'5000 (~/ or /home/$user).**
```
cd ~/
mv TPCx-AI_over_Grid5000/* ./
```

# References
Here are three GitHub repositories that I used during my internship :
- [Arthur Galet's repository](https://github.com/ArthurGalet/tpcx-ai-grid5000): where I get the base configuration files and scripts
- [Michalis Georgoulakis' repository](https://github.com/mikegeo98/Grid-5000-TPC-H-over-HDFS-Spark): Really helpful to learn how to set up disks on Grid'5000
- [Rui Liu's repository](https://github.com/csruiliu/tpcxai-supplement/) : resources to manually build the virtual environment to get rid of Conda.

# Tools used (and their versions)
List all the tools used for launching the benchmark and how/where to install them.

## Download links
**All archives must be placed in a directory named "archives" in the home of Grid'5000**
- hadoop 3.3.2 : [download](https://archive.apache.org/dist/hadoop/common/hadoop-3.2.2/hadoop-3.2.2.tar.gz)
- Spark 2.4.8 : [download](https://archive.apache.org/dist/spark/spark-2.4.8/spark-2.4.8.tgz)
- Python 3.7.13 : [download](https://www.python.org/ftp/python/3.7.17/Python-3.7.17.tgz)
- java 8 jdk : [download](https://javadl.oracle.com/webapps/download/AutoDL?BundleId=248219_ce59cff5c23f4e2eaf4e778a117d4c5b)
- TPCx-AI v1.0.2 : [fill the form](https://www.tpc.org/TPC_Documents_Current_Versions/download_programs/tools-download-request5.asp?bm_type=TPCX-AI&bm_vers=1.0.2&mode=CURRENT-ONLY)

## Procedure for hadoop, java8 and TPCx-AI
Once downloaded, untar hadoop and TPCx-AI
```
tar -zxf archive_name.tar.gz
```
Rename the extracted directories "hadoop" instead of "hadoop-3.3.2" and "tpcx-ai" instead of "tpcx-ai-v1.0.2".
Compress these two directories :
```
tar -czf dir_name
```
For java, just rename the archive "java8jdk.tar.gz"

# Adaptation to your environment
Even if I tried to make it as general as possible, the file "tpcxai-generation.xml" in "distr/deploy/tpcx-ai/lib/pdgf/config/tpcxai-generation.xml" still contains my username. It **MUST** be replaced by yours (you can use a simple sed command to do so).
```
sed -i 's/lruellou/your_username/g' distr/deploy/tpcx-ai/lib/pdgf/config/tpcxai-generation.xml
```

# Launch in distributed mode (over more than one node)
All you have to do is call the setup.sh script with two parameters:
- The number of loop: only useful when launching the experiments. I recommend to use '1' when launching tests.
- The name of the run : It will create two directories to store the spark logs and the metric produces by the benchmark to choose an explicit name. For example, "N4_SF10" when launching over 4 nodes with a scale factor of 10.

The explanations of the script can be found on the README file of the Arthur Galet's repository.

# Using the python scripts
I did not test those script on Grid'5000, only on my own computer.

## mean.py
This script calculate the mean of several csv files (they must have the same dimensions). For example, several run on the same configuration. The program will pick all csv files in the directory specified in the main block (line 85), and will create a csv file with the directory's name.
It will not take into account the extremes of each metrics (maximum and minimum).

## show_metrics.py
This script will pick all the csv files in the directory specified in line 106. Then plot a chart comparing the different metrics. It saves the figure in the directory : "figure/dir_name".

## Typical use
After running the benchmark on a wanted configuration (for example 4 nodes and different scale factors) with the "loop" parameter of the setup.sh script at five, you obtain several directories, each one containing five csv files with the metrics.
First, execute "mean.py" on each directory. Then gather all the csv files generated into the same directory with an explicit name like "Varying SF with 4 nodes".
Execute the "show_metrics.py" script with the directory "Varying SF with 4 nodes". It will generate a figure named "Varying SF with 4 nodes".

# Directories "metrics" and "figure"
These directories contain the result of my previous runs.

## metrics
Contains all the csv files resulting of the runs. They are grouped by 5 (corresponding to one run).
- NXX means a run with XX nodes and a scale factor of 10.
- SFXX means a run with a scale factor of XX over 8 nodes.
- Varying_SF : group the mean of the runs over 8 nodes, with different scale factors.
- Varying_nodes : group the mean of the runs with a scale factor of 10, with different number of nodes.

## figures
Contains the two figures resulting of my runs. Their names are explicit.


