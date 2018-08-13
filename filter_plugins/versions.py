from ansible.errors import AnsibleError
from ansible.plugins.lookup import LookupBase
from ansible.utils.listify import listify_lookup_plugin_terms

def version_v(s):
    """Return version with v prefix"""
    return 'v' + s.strip('v')

def version_n(s):
    """Return version as pure numeral without v prefix"""
    return s.strip('v')

class FilterModule(object):
    """Version filter"""
    def filters(self):
        return {
            'version_v': version_v,
            'version_n': version_n,
        }
