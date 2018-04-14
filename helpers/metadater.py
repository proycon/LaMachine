#!/usr/bin/env python3

#This script converts software metadata
#from different sources into a generic form.
#Attempting to reuse as much as possible from ADMS.SW and DOAP:
#https://joinup.ec.europa.eu/svn/adms_foss/adms_sw_v1.00/adms_sw_v1.00.htm

# Maarten van Gompel
# CLST, Radboud University Nijmegen
# GPL v3


import sys
import argparse
import subprocess
import yaml
import json
from itertools import chain
from collections import OrderedDict

def represent_ordereddict(dumper, data):
    value = []

    for item_key, item_value in data.items():
        node_key = dumper.represent_data(item_key)
        node_value = dumper.represent_data(item_value)

        value.append((node_key, node_value))

    return yaml.nodes.MappingNode('tag:yaml.org,2002:map', value)

yaml.add_representer(OrderedDict, represent_ordereddict)

properties = { #first order properties (including collections, i.e. properties that may be specified multiple times!)
    "doap:name": "The name of the software",
    "doap:revision": "The full version number of the software",
    "doap:description": "A brief description of what the software does",
    "doap:homepage": "The homepage of the software",
    "doap:developer": "The author of the software",
    "doap:maintainer": "The maintainer of the software",
    "doap:repository": "Source code repository",
    "doap:vendor": "Vendor/publisher",
    "doap:platform": "Platform (non-OS specific), e.g. Python, Java, Firefox, ECMA CLR",
    "dcterms:license": "The software license",
    "lamachine:dependency": "A dependency",
    "lamachine:interface": "An interface",
    "admssw:supportsFormat": "Supported data format", #ideally range is dcterms:FileFormat, we settle for plain mimetypes for now (we can also tie this directly to an interface, which is preferred!)
    "dcterms:created": "Date of creation",
    "dcterms:modified": "Last modified date",
    "foaf:logo": "Logo", #just a URL for now
    "rad:theme": "Theme/topic/domain of the software",
    "admssw:intendedAudience": "Intended Audience for the software",
    "rad:keyword": "Keyword for finding the software",
    "xhv:last": "Latest available version of the software (may be newer than the one actually installed! cf. doap:revision)",
    "lamachine:destination": "Location where the software is installed on disk", #(we can also tie this directly to an interface, which is preferred!)
    "schema:operatingSystem": "The operating system on which this software works",
    "admssw:status": "The development status of the software (e.g. alpha, beta, production, prerelease)",
    "admssw:programmingLanguage": "Programming language in which the software is written",
}

alias = { #just for convenience so common fields work out of the box
    "version": "doap:revision",
    "latest": "xhv:last",
    "author": "doap:developer",
    "summary": "doap:description",
    "home-page": "doap:homepage", #used by pip
    "title": "doap:name",
    "licence": "dcterms:license",
    "mimetype": "admssw:supportsFormat",
    "requires": "lamachine:dependency",
    "topic": "rad:theme", #used by pip
}

collections = {
    "authors": "doap:developer",
    "developers": "doap:developer", #overrides the previous one which is just an alias
    "dependencies": "lamachine:dependency",
    "interfaces": "lamachine:interface",
    "audiences": "admssw:intendedAudience",
    "topics": "rad:theme",
    "themes": "rad:theme", #overrides the previous one which is just an alias
    "keywords": "rad:keyword",
    "operatingSystems": "schema:operatingSystem",
    "programmingLanguages": "admssw:programmingLanguage",
}
incollection = { v:k for k,v in collections.items() }


dep_properties = {
    "doap:name": "The name of the dependency",
    "lamachine:externalPlatform": "Boolean, external dependencies are dependencies in a different software ecosystem. Internal dependencies are in the same ecosystem (e.g. Python/PyPI, Java/Maven, Perl/CPAN)",
    "lamachine:minimumVersion": "Minimum version",
    "lamachine:maximumVersion": "Maximum version",
}

interface_properties = {
    "lamachine:entrypoint": "The name of the executable, module, or an URL (depending on interfaceType)",
    "admssw:userInterfaceType": "User Interface Type", #for now we simply predefine: api (some for of shared library), cli (command line tool),  tui (Text UI), gui (Graphical UI), wui (Web UI), rest (REST webservice), soap (SOAP webservice), xmlrpc (other XMLRPC webservice), ws (other webservice)
    "admssw:supportsFormat": "Supported data format", #ideally range is dcterms:FileFormat, we settle for plain mimetypes for now
    "lamachine:destination": "Location where the software is installed on disk, may be more generic or differ from lamachine:entrypoint",
}


pip_mapping = { #we only need to cover the ones not already covered by common aliasses
    "Location": "lamachine:destination",
}

pip_classifier_mapping = { #we only need to cover the ones not already covered by common aliasses
    "Operating System": "schema:operatingSystem",
    "Development Status": "admssw:status",
    "Intended Audience": "admssw:intendedAudience",
    "Programming Language": "admssw:programmingLanguage",
    "License": "dcterms:license"
}


def qualify(key):
    if ':' in key:
        return key #already qualified
    for qkey in chain(properties, interface_properties, dep_properties):
        if qkey.split(':')[1].lower() == key.lower():
            return qkey
    for shortkey, qkey in alias.items():
        if key.lower() == shortkey.lower():
            return qkey
    raise KeyError("Unable to qualify key: " + key)


class SoftwareMetadata:
    def __init__(self, **kwargs):
        self.data = OrderedDict()
        self.update(kwargs)

    def update(self, d):
        for key, value in iterargs(d):
            if isinstance(value, (list,tuple)):
                for item in value:
                    self.add(key, item)
            else:
                self.add(key, value)
        for collection, key in collections.items():
            if collection in d:
                for item in d[collection]:
                    if isinstance(item, dict):
                        self.add(qualify(key), { qualify(k):v for k,v in item.items() })
                    else:
                        self.add(qualify(key), item)

    def resolvekey(self, key):
        if ':' in key:
            #key is fully qualified
            if key not in properties:
                raise KeyError("No such key: ", key)
        else:
            key = qualify(key)
        return key

    def incollection(self, key):
        if key in incollection:
            return incollection[key]
        else:
            return False

    def add(self, key, value):
        key = self.resolvekey(key)
        collection = self.incollection(key)
        if isinstance(value, str):
            value = value.strip().replace("\n"," ").replace("\r","")
        if collection:
            nested = False
            if key == 'lamachine:interface' and not isinstance(value, (list,tuple, dict)):
                value = {"lamachine:entrypoint": value}
                nested =True
            elif key == 'lamachine:dependency' and not isinstance(value, (list,tuple, dict)):
                value = {"doap:name": value}

            if isinstance(value, (list,tuple)) and not isinstance(value, (list,tuple)):
                self.data[collection] = value
            if nested:
                if isinstance(value, dict):
                    self.data[collection].append(value)
                else:
                    raise ValueError
            else:
                if collection not in self.data: self.data[collection] = []
                self.data[collection].append(value)
        else:
            self.data[key] = value

    def __setitem__(self, key, value):
        self.data[key] = value

    def __contains__(self, key):
        key = self.resolvekey(key)
        return key in self.data

    def __getitem__(self, key):
        key = self.resolvekey(key)
        collection = self.incollection(key)
        if collection:
            return self.data[collection]
        else:
            return self.data[key]


    def __items__(self):
        for x in self.data.items():
            yield x

    def __len__(self):
        return len(self.data)

    def dequalify(self, d=None):
        """Return a simple dictionary without any namespaces, good for simple serialisation"""
        out = OrderedDict()
        if d is None: d = self.data
        for key, value in d.items():
            if isinstance(value, (dict, OrderedDict)):
                value = self.dequalify(value)
            if key in collections:
                out[key.lower()] = []
                for item in value:
                    if isinstance(item, (dict, OrderedDict)):
                        out[key.lower()].append(self.dequalify(item))
                    else:
                        out[key.lower()].append(item)
            elif ':' in key:
                key = key.split(':')[1]
                out[key.lower()] = value
            else:
                out[key.lower()] = value #nothing to do
        return out

    def yaml(self):
        return yaml.dump({ self['doap:name'].lower().replace(" ","_"): self.dequalify()}, default_flow_style=False)

    def json(self):
        return json.dumps({ self['doap:name'].lower().replace(" ","_"): self.dequalify()}, ensure_ascii=False, indent=4)



def parsepip(data, lines):
    section = None
    for line in lines:
        if line.strip() == "Classifiers:":
            section = "classifiers"
        elif line.strip() == "Entry-points:":
            section = "interfaces"
        elif section == "classifiers":
            fields = [ x.strip() for x in line.strip().split('::') ]
            if fields[0] in pip_classifier_mapping:
                data.add(pip_classifier_mapping[fields[0]], " :: ".join(fields[1:]))
            elif fields[0].lower() in alias:
                data.add(fields[0], " :: ".join(fields[1:]))
            else:
                print("WARNING: Classifier "  + fields[0] + " has no translation",file=sys.stderr)
        elif section == "interfaces":
            if line.strip() == "[console_scripts]":
                pass
            elif line.find('=') != -1:
                fields = line.split('=')
                data.add('lamachine:interface',{'lamachine:entrypoint': fields[0].strip(), 'admssw:userInterfaceType': 'cli'})
        else:
            try:
                key, value = line.split(':',1)
            except:
                continue
            if key == "Author-email":
                if "doap:developer" in data:
                    data["doap:developer"][0] += " <" + value.strip() + ">"
            elif key == "Requires":
                for dependency in value.split(','):
                    if dependency.strip():
                        data.add('lamachine:dependency',{'doap:name': dependency.strip(), 'lamachine:externalPlatform': False})
            elif key == "Requires-External":
                for dependency in value.split(','):
                    if dependency.strip():
                        data.add('lamachine:dependency',{'doap:name': dependency.strip(), 'lamachine:externalPlatform': True})
            elif key in pip_mapping:
                data.add(pip_mapping[key], value)
            else:
                try:
                    data.add(key, value)
                except KeyError:
                    print("WARNING: No translation for pip key " + key,file=sys.stderr)

    data.add('platform', 'Python')


def iterargs(args):
    if isinstance(args, argparse.Namespace):
        args = vars(args)
    for shortkey, key in alias.items():
        if shortkey in args and args[shortkey]:
            yield key, args[shortkey]
    for key in properties:
        shortkey = key.split(':')[1]
        if shortkey in args and args[shortkey]:
            yield key, args[shortkey]

def main():
    parser = argparse.ArgumentParser(description="LaMachine Metadater")
    parser.add_argument('--pip', type=str,help="Query through pip, supply the package name", action='store',required=False)
    parser.add_argument('--yaml', help="Read metadata from standard input (YAML format)", action='store_true',required=False)
    parser.add_argument('--output', type=str,help="Metadata output type: yaml (default), json", action='store',required=False, default="yaml")
    for key, help in properties.items():
        shortkey = key.split(':')[1]
        if key in incollection:
            parser.add_argument('--' + shortkey, type=str,nargs='*', help=help + " (" +  key + ")", action='store',required=False)
        else:
            parser.add_argument('--' + shortkey, type=str,help=help + " (" + key +  ")", action='store',required=False)
    for shortkey, key in alias.items():
        if key in incollection:
            parser.add_argument('--' + shortkey, type=str,nargs='*', help="Alias for --"+ key.split(':')[1] +": " + properties[key], action='store',required=False)
        else:
            parser.add_argument('--' + shortkey, type=str,help="Alias for --"+ key.split(':')[1] +": " + properties[key], action='store',required=False)

    args = parser.parse_args()

    data = SoftwareMetadata()
    if args.yaml:
        data.update(yaml.load(sys.stdin))
    if args.pip:
        process = subprocess.Popen('pip show -v "' + args.pip +  '"', stdout=subprocess.PIPE, shell=True)
        out, _ = process.communicate()
        out = str(out, 'utf-8')
        parsepip(data, out.split("\n"))

    data.update(args)
    if 'doap:name' in data:
        if args.output == "yaml":
            print(data.yaml())
        elif args.output == "json":
            print(data.json())

if __name__ == '__main__':
    main()
