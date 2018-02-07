#!/usr/bin/python
# -*- coding: utf-8 -*-

DOCUMENTATION = """
---
module: conda
short_description: Manage Python libraries via conda
description:
  >
    Manage Python libraries via conda.
    Can install, update, and remove packages.
author: 
  - Synthicity
  - Colin Nolan (@colin-nolan)
notes:
  >
    Requires conda to already be installed.
options:
  name:
    description: The name of a Python package to install.
    required: true
  version:
    description: The specific version of a package to install.
    required: false
  state:
    description: State in which to leave the Python package. "present" will install a package of the specified version 
                 if it is not installed (will not upgrade to latest if version is unspecified - will only install  
                 latest); "latest" will both install and subsequently upgrade a package to the latest version on each 
                 run; "absent" will uninstall the package if installed.
    required: false
    default: present
    choices: [ "present", "absent", "latest" ]
  channels:
    description: Extra channels to use when installing packages.
    required: false
  executable:
    description: Full path to the conda executable.
    required: false
  extra_args:
    description: Extra arguments passed to conda.
    required: false
"""

EXAMPLES = """
- name: install numpy via conda
  conda: 
    name: numpy
    state: latest

- name: install scipy 0.14 via conda
  conda: 
    name: scipy 
    version: "0.14"

- name: remove matplotlib from conda
  conda: 
    name: matplotlib 
    state: absent
"""

RETURN = """
output:
    description: JSON output from Conda
    returned: `changed == True`
    type: dict
stderr:
    description: stderr content written by Conda
    returned: `changed == True`
    type: str
"""


from distutils.spawn import find_executable
import os.path
import json
from ansible.module_utils.basic import AnsibleModule


def run_package_operation(conda, name, version, state, dry_run, command_runner, on_failure, on_success):
    """
    Runs Conda package operation.

    This method is intentionally decoupled from `AnsibleModule` to allow it to be easily tested in isolation.
    :param conda: location of the Conda executable
    :param name: name of the package of interest
    :param version: version of the package (`None` for latest)
    :param state: state the package should be in
    :param dry_run: will "pretend" to make changes only if `True`
    :param command_runner: method that executes a given Conda command (given as list of string arguments), which returns
    JSON and returns a tuple where the first argument is the outputted JSON and the second is anything written to stderr
    :param on_failure: method that takes any kwargs to be called on failure
    :param on_success: method that takes any kwargs to be called on success
    """
    correct_version_installed = check_package_installed(command_runner, conda, name, version)

    # TODO: State should be an "enum" (or whatever the Py2.7 equivalent is)
    if not correct_version_installed and state != 'absent':
        try:
            output, stderr = install_package(command_runner, conda, name, version, dry_run=dry_run)
            on_success(changed=True, output=output, stderr=stderr)
        except CondaPackageNotFoundError:
            on_failure(msg='Conda package "%s" not found' % (get_install_target(name, version, )))

    elif state == 'absent':
        try:
            output, stderr = uninstall_package(command_runner, conda, name, dry_run=dry_run)
            on_success(changed=True, output=output, stderr=stderr)
        except CondaPackageNotFoundError:
            on_success(changed=False)

    else:
        on_success(changed=False)


def check_package_installed(command_runner, conda, name, version):
    """
    Check whether a package with the given name and version is installed.
    :param command_runner: method that executes a given Conda command (given as list of string arguments), which returns
    JSON and returns a tuple where the first argument is the outputted JSON and the second is anything written to stderr
    :param name: the name of the package to check if installed
    :param version: the version of the package to check if installed (`None` if check for latest)
    :return: `True` if a package with the given name and version is installed
    :raises CondaUnexpectedOutputError: if the JSON returned by Conda was unexpected
    """
    output, stderr = run_conda_package_command(
        command_runner, name, version, [conda, 'install', '--json', '--dry-run', get_install_target(name, version)])

    if 'message' in output and output['message'] == 'All requested packages already installed.':
        return True
    elif 'actions' in output and len(output['actions']) > 0:
        return False
    else:
        raise CondaUnexpectedOutputError(output, stderr)


def install_package(command_runner, conda, name, version=None, dry_run=False):
    """
    Install a package with the given name and version. Version will default to latest if `None`.
    """
    command = [conda, 'install', '--yes', '--json', get_install_target(name, version)]
    if dry_run:
        command.insert(-1, '--dry-run')

    return run_conda_package_command(command_runner, name, version, command)


def uninstall_package(command_runner, conda, name, dry_run=False):
    """
    Use Conda to remove a package with the given name.
    """
    command = [conda, 'remove', '--yes', '--json', name]
    if dry_run:
        command.insert(-1, '--dry-run')

    return run_conda_package_command(command_runner, name, None, command)


def find_conda(executable):
    """
    If `executable` is not None, checks whether it points to a valid file
    and returns it if this is the case. Otherwise tries to find the `conda`
    executable in the path. Calls `fail_json` if either of these fail.
    """
    if not executable:
        conda = find_executable('conda')
        if conda:
            return conda
    else:
        if os.path.isfile(executable):
            return executable

    raise CondaExecutableNotFoundError()


def add_channels_to_command(command, channels):
    """
    Add extra channels to a conda command by splitting the channels
    and putting "--channel" before each one.
    """
    if channels:
        channels = channels.strip().split()
        dashc = []
        for channel in channels:
            dashc.append('--channel')
            dashc.append(channel)

        return command[:2] + dashc + command[2:]
    else:
        return command


def add_extras_to_command(command, extras):
    """
    Add extra arguments to a conda command by splitting the arguments
    on white space and inserting them after the second item in the command.
    """
    if extras:
        extras = extras.strip().split()
        return command[:2] + extras + command[2:]
    else:
        return command


def parse_conda_stdout(stdout):
    """
    Parses the given output from Conda.
    :param stdout: the output from stdout
    :return: standard out as parsed JSON else `None` if non-JSON format
    """
    # Conda spews loading progress reports onto stdout(!?), which need ignoring. Bug observed in Conda version 4.3.25.
    split_lines = stdout.strip().split("\n")
    while len(split_lines) > 0:
        line = split_lines.pop(0).strip('\x00')
        try:
            line_content = json.loads(line)
            if "progress" not in line_content and "maxval" not in line_content:
                # Looks like this was the output, not a progress update
                return line_content
        except ValueError:
            split_lines.insert(0, line)
            break

    try:
        return json.loads("".join(split_lines))
    except ValueError:
        return None


def run_conda_package_command(command_runner, name, version, command):
    """
    Runs a Conda command related to a particular package.
    :param command_runner: runner of Conda commands
    :param name: the name of the package the command refers to
    :param version: the version of the package that the command is referring to
    :param command: the Conda command
    :raises CondaPackageNotFoundError: if the package referred to by this command is not found
    """
    try:
        return command_runner(command)
    except CondaCommandJsonDescribedError as e:
        if 'exception_name' in e.output and e.output['exception_name'] == 'PackageNotFoundError':
            raise CondaPackageNotFoundError(name, version)
        else:
            raise


def get_install_target(name, version):
    """
    Gets install target string for a package with the given name and version.
    :param name: the package name
    :param version: the package version (`None` if latest)
    :return: the target string that Conda can refer to the given package as
    """
    install_target = name
    if version is not None:
        install_target = '%s=%s' % (name, version)
    return install_target


class CondaCommandError(Exception):
    """
    Error raised when a Conda command fails.
    """
    def __init__(self, command, stdout, stderr):
        self.command = command
        self.stdout = stdout
        self.stderr = stderr

        stdout = ' stdout: %s.' % self.stdout if self.stdout.strip() != '' else ''
        stderr = ' stderr: %s.' % self.stderr if self.stderr.strip() != '' else ''

        super(CondaCommandError, self).__init__(
            'Error running command: %s.%s%s' % (self.command, stdout, stderr))


class CondaCommandJsonDescribedError(CondaCommandError):
    """
    Error raised when a Conda command does not output JSON.
    """
    def __init__(self, command, output, stderr):
        self.output = output
        super(CondaCommandJsonDescribedError, self).__init__(command, json.dumps(output), stderr)


class CondaPackageNotFoundError(Exception):
    """
    Error raised when a Conda package has not been found in the package repositories that were searched.
    """
    def __int__(self, name, version):
        self.name = name
        self.version = version
        super(CondaPackageNotFoundError, self).__init__(
            'Conda package "%s" not found' % (get_install_target(self.name, self.version), ))


class CondaUnexpectedOutputError(Exception):
    """
    Error raised when the running of a Conda command has resulted in an unexpected output.
    """
    def __int__(self, output, stderr):
        self.output = output
        self.stderr = stderr

        stderr = 'stderr: %s' % self.stderr if self.stderr.strip() != '' else ''
        super(CondaUnexpectedOutputError, self).__init__(
            'Unexpected output from Conda (may be due to a change in Conda\'s output format): "%output".%s'
            % (self.output, stderr))


class CondaExecutableNotFoundError(Exception):
    """
    Error raised when the Conda executable was not found.
    """
    def __init__(self):
        super(CondaExecutableNotFoundError, self).__init__('Conda executable not found.')


def _run_conda_command(module, command):
    """
    Runs the given Conda command.
    :param module: Ansible module
    :param command: the Conda command to run, which must return JSON
    """
    command = add_channels_to_command(command, module.params['channels'])
    command = add_extras_to_command(command, module.params['extra_args'])

    rc, stdout, stderr = module.run_command(command)
    output = parse_conda_stdout(stdout)

    if output is None:
        raise CondaCommandError(command, stdout, stderr)
    if rc != 0:
        raise CondaCommandJsonDescribedError(command, output, stderr)

    return output, stderr


def _main():
    """
    Entrypoint.
    """
    module = AnsibleModule(
        argument_spec={
            'name': {'required': True, 'type': 'str'},
            'version': {'default': None, 'required': False, 'type': 'str'},
            'state': {
                'default': 'present',
                'required': False,
                'choices': ['present', 'absent', 'latest']
            },
            'channels': {'default': None, 'required': False},
            'executable': {'default': None, 'required': False},
            'extra_args': {'default': None, 'required': False, 'type': 'str'}
        },
        supports_check_mode=True)

    conda = find_conda(module.params['executable'])
    name = module.params['name']
    state = module.params['state']
    version = module.params['version']

    if state == 'latest' and version is not None:
        module.fail_json(msg='`version` must not be set if `state == "latest"` (`latest` upgrades to newest version)')

    def command_runner(command):
        return _run_conda_command(module, command)

    run_package_operation(
        conda, name, version, state, module.check_mode, command_runner, module.fail_json, module.exit_json)


if __name__ == '__main__':
    _main()
