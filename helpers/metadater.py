#!/usr/bin/env python3

import argparse
import subprocess
import yaml

#Attempting to reuse as much as possible from ADMS.SW and DOAP:
#https://joinup.ec.europa.eu/svn/adms_foss/adms_sw_v1.00/adms_sw_v1.00.htm

pip_mapping = {
    "Name": "doap:name",
    "Version": "doap:revision",
    "Summary": "doap:description",
    "Home-page": "doap:homepage",
    "Author": "doap:developer",
    "Licence": "dcterms:license",
    "Requires": "lamachine:dependencies",
}
pip_classifier_mapping = {
    "Operating System": "schema:operatingSystem",
}

def parsepip(lines):
    data = {}
    section = None
    for line in lines:
        if line.strip() = "Classifiers:":
            section = "classifiers"
        elif line.strip() = "Entry-points:":
            section = "interfaces"
        elif section == "classifiers":
        elif section == "interfaces":

        else:
            key, value = line.split(':',1)
            if key in mapping:
                data[mapping[key].split(':',1)[1:]] = value
            elif key == "Author-email":
                data['developer'] += " <" + value + ">"

    if 'developer' in data:
        data['maintainer'] = data['developer']
    return data


def main():
    parser = argparse.ArgumentParser(description="LaMachine Metadater", formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument('--pip', type=str,help="from pip", action='store',required=False)
    parser.add_argument('data', nargs='*', help='Data')
    args = parser.parse_args()

    if args.pip:
        process = subprocess.Popen('pip show -v "' + args.pip +  '"', stdout=subprocess.PIPE, shell=True)
        out, _ = process.communicate()
        data = parsepip(out.split("\n"))

    yaml.dump(data)

if __name__ == '__main__':
    main()
