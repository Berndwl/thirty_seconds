from os import listdir
from os.path import join
import json

path = "/Users/Bernd/IdeaProjects/thirty_seconds/lib/words/raw"
out_path = "/Users/Bernd/IdeaProjects/thirty_seconds/lib/words/out.json"

json_string = '{"dutch": []}'
json_data = json.loads(json_string)

for file in listdir(path):
    clean_file_name = file.strip('.txt')
    file_name_path = join(path, file)

    json_temp_string = '{"'+clean_file_name+'": []}'
    new_json_data = json.loads(json_temp_string)

    with open(file_name_path, 'r') as txt:
        for line in txt:
            if(line != '' and line != '\n' and not line.startswith('#')):
                new_json_data[clean_file_name].append(line.strip())

    json_data['dutch'].append(new_json_data)



with open(out_path, 'w') as out_file:
    json.dump(json_data, out_file)