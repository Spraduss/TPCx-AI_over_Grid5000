"""
How to use this script ?

"""

import csv
import os

import matplotlib.pyplot as plt

# Map with file name as key and file path as value
files_path = {}

# Stores all the metrics for each file
main = {}

# List the quality metrics' name per use case
quality_metrics = {}

# List the different use cases
use_cases = []


def get_files_from_path(file_directory):
    for filename in os.listdir(file_directory):
        # Create a map : file_name -> path_to_file
        f = os.path.join(file_directory, filename)
        if os.path.isfile(f) and filename.endswith('.csv'):
            files_path[filename[:len(filename) - 4]] = f  # File's name without ".csv"

        # Extract the content of the file
        for file_name in files_path:
            read_one_metrics(file_name)
    return


def read_one_metrics(file_name):
    """
    Read a single file "metricX.csv", extract the datas and put them in the right
    place in the dico 'main'
    :param file_name : the name of the wanted file
    """
    main[file_name] = {}
    with open(files_path[file_name], newline='') as file:
        reader = csv.reader(file)
        first_line = True
        for row in reader:
            if first_line:
                # we skip the label line and only consider the use cases
                first_line = False
            else:
                quality_metrics[row[0]] = row[3]
                # UC number
                main[file_name][row[0]] = {"serving": 0, "training": 0, row[3]: 0}
                if not row[0] in use_cases:
                    use_cases.append(row[0])
                # Serving
                main[file_name][row[0]]["serving"] = float(row[1])
                # Training
                main[file_name][row[0]]["training"] = float(row[2])
                # Metric value
                main[file_name][row[0]][row[3]] = float(row[4])
    return


def get_one_uc_datas(uc):
    """
    Read all the datas needed for a given use case
    :param uc: the use case's number
    :return:
    """
    training = []
    serving = []
    quality_metric = []
    for name in main:
        training.append(main[name][str(uc)]["training"])
        serving.append(main[name][str(uc)]["serving"])
        quality_metric.append(main[name][str(uc)][quality_metrics[str(uc)]])
    return {"training": training, "serving": serving, quality_metrics[str(uc)]: quality_metric}


def plot(fig_name):
    color_list = ['tab:blue', 'tab:orange', 'tab:green', 'tab:red', 'tab:purple', 'tab:brown', 'tab:pink', 'tab:olive']
    names = list(main.keys())
    fig, axes = plt.subplots(len(use_cases), 3, figsize=(12, 10))
    fig.tight_layout()
    i = 0
    for uc in use_cases:
        # enumerate through the different UC
        datas = get_one_uc_datas(uc)
        ylabel = "UC " + str(uc)
        axes[i, 0].bar(names, datas["serving"], width=0.8, color=color_list)
        axes[i, 0].set_ylabel(ylabel)
        axes[i, 1].bar(names, datas["training"], width=0.8, color=color_list)
        axes[i, 2].bar(names, datas[quality_metrics[uc]], width=0.8, color=color_list)
        axes[i, 2].set_title(quality_metrics[uc])
        i += 1
    axes[0, 0].set_title("Serving time (s)")
    axes[0, 1].set_title("Training time (s)")
    axes[0, 2].set_title("Quality metric")
    save_path = "./figures/"+fig_name
    plt.savefig(save_path)


if __name__ == "__main__":
    dir = "Varying_SF"
    directory = './metrics/'+dir
    get_files_from_path(directory)
    plot(dir)
