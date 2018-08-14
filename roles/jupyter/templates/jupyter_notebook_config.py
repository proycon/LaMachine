c.NotebookApp.password_required = True
c.NotebookApp.allow_origin = '{{lab_allow_origin}}'
c.NotebookApp.base_url = '/lab'
c.NotebookApp.password = '{{lab_password_sha1}}'
c.NotebookApp.port = 9888
c.NotebookApp.trust_xheaders = True #necessary if reverse proxy handles SSL
#c.NotebookApp.nbserver_extensions = {"jupyterlab_git": True}
