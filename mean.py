import csv
import os


training = {}  # UC -> training_time
serving = {}  # UC -> serving_time
q_metric = {}  # UC -> q_metric_val
mean_training = {}
mean_serving = {}
mean_q_metric = {}

use_cases = []
q_metric_names = {}  # UC -> q_metric_name
file_dir = ""


def get_mean(file_directory):
    global file_dir
    file_dir = str(file_directory)
    init_dicts()
    for filename in os.listdir(file_directory):
        file_path = os.path.join(file_directory, filename)
        if os.path.isfile(file_path) and filename.endswith('.csv'):
            # Extract the content of the file
            read_one_file(file_path)
    calculate_mean()
    return


def init_dicts():
    for i in range(10):
        q_metric_names[str((i+1))] = ''
        # Serving
        serving[str((i+1))] = []
        mean_serving[str((i+1))] = 0
        # Training
        training[str((i+1))] = []
        mean_training[str((i+1))] = 0
        # Metric value
        q_metric[str((i+1))] = []
        mean_q_metric[str((i+1))] = 0
    return


def read_one_file(file_path):
    with open(file_path, newline='') as file:
        reader = csv.reader(file)
        first_line = True
        for row in reader:
            if first_line:
                # we skip the label line and only consider the use cases
                first_line = False
            else:
                if str(row[0]) not in use_cases:
                    use_cases.append(str(row[0]))
                q_metric_names[str(row[0])] = str(row[3])
                # Serving
                serving[str(row[0])].append(float(row[1]))
                # Training
                training[str(row[0])].append(float(row[2]))
                # Metric value
                q_metric[str(row[0])].append(float(row[4]))
    return


def calculate_mean():
    for uc in use_cases:
        mean_training[uc] = (sum(training[uc]) - max(training[uc]) - min(training[uc])) / (len(training[uc]) - 2)
        mean_serving[uc] = (sum(serving[uc]) - max(serving[uc]) - min(serving[uc])) / (len(serving[uc]) - 2)
        mean_q_metric[uc] = (sum(q_metric[uc]) - max(q_metric[uc]) - min(q_metric[uc])) / (len(q_metric[uc]) - 2)
    write_file()
    return


def write_file():
    with open(file_dir + '.csv', 'w', newline='') as file:
        writer = csv.writer(file)
        field = ["use_case", "Phase.SERVING_1", "Phase.TRAINING_1", "quality_metric_name", "quality_metric_value"]
        writer.writerow(field)
        for uc in use_cases:
            writer.writerow([uc, mean_serving[uc], mean_training[uc], q_metric_names[uc], mean_q_metric[uc]])


if __name__ == "__main__":
    directory = './metrics/SF15'
    get_mean(directory)
