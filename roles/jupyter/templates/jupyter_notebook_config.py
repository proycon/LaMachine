c.NotebookApp.password_required = True
c.NotebookApp.allow_origin = '{{lab_allow_origin}}'
c.NotebookApp.trust_xheaders = True #necessary if reverse proxy handles SSL
c.NotebookApp.notebook_dir = '{{www_data_path}}/notebooks'
c.NotebookApp.terminado_settings = { 'shell_command': ['/bin/bash','-l'] }
#c.NotebookApp.nbserver_extensions = {"jupyterlab_git": True}
