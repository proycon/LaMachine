#!/usr/bin/env python3

#This script converts software metadata
#from different sources into a generic form.
#Attempting to reuse as much as possible from ADMS.SW and DOAP:
#https://joinup.ec.europa.eu/svn/adms_foss/adms_sw_v1.00/adms_sw_v1.00.htm


import argparse
import subprocess
import yaml

properties = {
    "doap:name": "The name of the software",
    "doap:revision": "The full version number of the software",
    "doap:description": "A brief description of what the software does",
    "doap:homepage": "The homepage of the software",
    "doap:developer": "The author of the software (can be used multiple times!)",
    "dcterms:license": "The software license",
    "lamachine:dependency": "A dependency",
}

dep_properties = {
    "doap:name": "The name of the software",
    "lamachine:externalDependency": "Boolean, external dependencies are dependencies in a different software ecosystem. Internal dependencies are in the same ecosystem (e.g. Python/PyPI, Java/Maven, Perl/CPAN)",
    "lamachine:minimumVersion": "Minimum version",
    "lamachine:maximumVersion": "Maximum version",
}


pip_mapping = {
    "Name": "doap:name",
    "Version": "doap:revision",
    "Summary": "doap:description",
    "Home-page": "doap:homepage",
    "Author": "doap:developer",
    "Licence": "dcterms:license",
    "Requires": "lamachine:dependencies",
    "Location": "lamachine:installLocation",
}
pip_classifier_mapping = {
    "Operating System": "schema:operatingSystem",
    "Development Status": "admssw:status",
    "Topic": "rad:theme",
    "Indented Audience": "admssw:intendedAudience",
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
            fields = line.strip().split('::')
            if fields[0] in mapping:
                data[pip_classifier_mapping[fields[0]].split(':',1)[1:]] = "


        elif section == "interfaces":

        else:
            key, value = line.split(':',1)
            if key in mapping:
                data[pip_mapping[key].split(':',1)[1:]] = value
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
