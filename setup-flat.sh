#This script is not meant to be called directly

export PYTHONPATH=$(pwd)/src/LaMachine
export DJANGO_SETTINGS_MODULE=flat_settings

django-admin makemigrations
django-admin migrate --run-syncdb

#create superuser automatically if it does not exist already
USER="flat"
PASS="flat"
MAIL="flat@localhost"
script="
from django.contrib.auth.models import User

username = '$USER'
password = '$PASS'
email = '$MAIL'

if User.objects.filter(username=username).count()==0:
    User.objects.create_superuser(username, email, password)
    print('Superuser created.')
else:
    print('Superuser creation skipped.')
"
printf "$script" | django-admin shell
