##############################################################################
#   FoLiA Linguistic Annotation Tool (FLAT) - Settings file
#
# These are the settings for your FLAT site.
#
# IMPORTANT NOTE: This file is managed by LaMachine, it will be overwritten on update
#                 Set custom_flat_settings = true in your LaMachine configuration
#                 if you want to keep your changes!
#
#---------------------------------------------------------------------------
#               PREAMBLE (don't edit this part)
#---------------------------------------------------------------------------
from django import VERSION as DJANGOVERSION
from socket import gethostname
import os.path
from os import environ
import flat


VERSION = flat.VERSION
try:
    BASE_DIR = os.path.dirname(os.path.dirname(flat.__file__)) + "/"
except:
    BASE_DIR = os.path.dirname(os.path.dirname(flat.__path__)) + "/"
hostname = gethostname()


##############################################################################
#               DATABASE CONFIGURATION (edit me!)
##############################################################################

#Configure your database here, by default a simple sqlite database will be used
DBFILE = "{{www_data_path}}/flat.db"
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.sqlite3', # Add 'postgresql_psycopg2', 'mysql', 'sqlite3' or 'oracle'.
        'NAME': DBFILE,                      # Or path to database file if using sqlite3.
        # The following settings are not used with sqlite3:
        'USER': '',
        'PASSWORD': '',
        'HOST': '',                      # Empty for localhost through domain sockets or '127.0.0.1' for localhost through TCP.
        'PORT': '',                      # Set to empty string for default.
    }
}


##############################################################################
#               FOLIA DOCUMENT SERVER CONFIGURATION (edit me!)
##############################################################################

#This is the path to the document root directory, this is the same directory as specified when running foliadocserve.
#If the document server is running on a different system, the remote root disk will have to be mounted and the mountpoint specified here.
WORKDIR = "{{www_data_path}}/flat.docroot"

#The path and port on which the FoLiA Document Server can be reached (these defaults suffice for a local connection)
FOLIADOCSERVE_HOST = 'localhost'
FOLIADOCSERVE_PORT = 3030

# Make sure to start the document server when starting FLAT!
#   $ foliadocserve -d /path/to/document/root -p 3030


##############################################################################
#               FLAT CONFIGURATION (edit me!)
##############################################################################


# FLAT consists of several modes, the user can select a mode from the menu.
# Each enables the user to do completely different things.
# The following modes are available and enabled. Simply
# comment the ones you want to disable:
MODES = [
    ('viewer','Viewer'),
    ('editor','Annotation Editor'),
    ('structureeditor','Structure Editor'),
    ('metadata','Metadata Editor'),
]

# The viewer and editor allow for different perspectives on the data.
#  - document: view of the entire document
#  - toc: view of a named subsection of the document (a table of contents will
#  be automatically constructed)
#  - any other FoLiA XML tag corresponsing to a structural element: paged data
#  over this type of element
PERSPECTIVES = [ 'document', 'toc', 'p', 's' ]


# Which mode should be used by default when the user opens a document?
DEFAULTMODE = 'editor'

# You may have several configurations for FLAT, a configuration determines what
# features will be enabled and what defaults will be set. Enabling all features
# will often be daunting and confusing for end-users. Using the configurations,
# you can fine-tune what users will see based on what is needed for your
# project(s).

# Users choose a configuration when logging in, the following configuration
# will be selected by default:
DEFAULTCONFIGURATION = 'full'

# Allow public anonymous uploads without any authentication?
ALLOWPUBLICUPLOAD = True #DISABLE THIS IF YOU DO NOT NEED ANY ANONYMOUS UNAUTHENTICATED USAGE!

ALLOWREGISTRATION = True

#These are the configurations, add new ones by copying the 'full' configuration and adapting it to your needs.
CONFIGURATIONS = {
'full':{
    # This is the 'full' configuration, it will enable all available functionality and is not fine-tuned for any specific task

    # The name of the mode, this is what users will see in the login screen,
    # make sure the name is indicative of your annotation project, if any
    'name': "Full Editor",

    # use the editor modes defined globally, or specify them explicitly per configuration here.
    'modes': MODES,

    # use the perspectives defined globally, or specify them explicitly per configuration here.
    'perspectives': PERSPECTIVES,


    # Allow users to upload FoLiA documents?
    'allowupload': True, #boolean

    #Automatically create namespaces for all the groups a user is in and has write permission for,
    'creategroupnamespaces': True, #boolean

    # The default annotation focus upon loading a document
    # The annotation type that has is set as annotation focus will be
    # visualised. Set to a valid FoLiA tag name (see the FoLiA documentation at
    # https://proycon.github.io/folia) or None to start without a specific focus
    'annotationfocustype': None,
    # If you set the above, you will also need to set what FoLiA set to use
    'annotationfocusset': None,

    #EXAMPLES:
    #'annotationfocustype': 'correction',
    #'annotationfocusset': 'http://raw.github.com/proycon/folia/master/setdefinitions/spellingcorrection.foliaset.xml',

    #'annotationfocustype': 'entity',
    #'annotationfocusset': 'https://raw.githubusercontent.com/proycon/folia/master/setdefinitions/namedentities.foliaset.xml',


    # Automatically enable the select span button for the annotation focus when opening the editor dialog
    'autoselectspan': False,


    # List of FoLiA annotation types (xml tags) that are allowed as annotation focus, set to True to enable all.
    # Users may switch annotation focus through the menu
    # Here and everywhere else, the annotation type equals the FoLiA XML tag
    # for the annotation, specific sets may be attached to annotation types using a slash, for example:
    #     entity/https://raw.githubusercontent.com/proycon/folia/master/setdefinitions/namedentities.foliaset.xml
    'allowedannotationfocus': True,

    #EXAMPLE:
    #'allowedannotationfocus': ('entity/https://raw.githubusercontent.com/proycon/folia/master/setdefinitions/namedentities.foliaset.xml'),

    # List of FoLiA annotation types (xml tags) that are initially enabled in
    # the local annotation viewer (the pop-up when the user hovers over elements)
    # set to True to enable all
    'initialviewannotations': True,


    # List of FoLiA annotation types (xml tags) that are initially enabled in
    # the global annotation viewer (in the annotation box above the words)
    'initialglobviewannotations': [],

    # List of FoLiA annotation types (xml tags) that are allowed to be viewed,
    # a superset of initialviewannotations/initialglobviewannotations. Users can enable/disable each as
    # they see fit. Set to True to enable all
    'allowedviewannotations': True,

    # List of FoLiA annotation types (xml tags) that are initially enabled in the editor dialog (when users click an element for editing)
    # set to True to enable all
    'initialeditannotations': True,

    # List of FoLiA annotation types (xml tags) that are allowed in the editor
    # dialog (the user can enable/disable each as he/she sees fit), set to True
    # to enable all
    'allowededitannotations': True,

    # Allow the user to add annotation types not yet present on a certain element?
    # If set to False, users can only edit existing annotations, never add new ones
    'allowaddfields': True, #boolean


    # Allow the user to add annotation types not yet present in the document?
    'allowdeclare': True, #boolean


    # The following values correspond to edit forms,
    # They are shown as a set of option buttons in the editor dialog, between
    # which the user can choose. Each of these options enables a button (if
    # only one is selected, no buttons appear). The edit forms can be
    # enabled/disabled by the user from a menu.

    #Enable direct editing (this is the default and most basic form of editing)
    #It should be True unless you want to force other editing forms
    'editformdirect': True, #boolean

    #Enable editing as correction
    'editformcorrection': False, #boolean

    #Enable editing as alternative
    'editformalternative': False, #boolean

    #Enable editing as new, this allows for adding multiple or overlapping annotations of the same type
    'editformnew': True, #boolean


    #This defines what edit modes the user can enable/disable from the menu
    'alloweditformdirect': True, #boolean
    'alloweditformcorrection': True, #boolean
    'alloweditformalternative': True, #boolean
    'alloweditformnew': True, #boolean

    #Allow confidence values to be set/edited?
    'allowconfidence': True,

    # FoLiA set to use for corrections
    #'initialcorrectionset': 'http://raw.github.com/proycon/folia/master/setdefinitions/spellingcorrection.foliaset.xml',

    # List of 2-tuples (tag,set) that specify what annotation types and with
    # what sets to declare automatically for each document that is opened.
    # (recall that FoLiA demands all annotations to be declared and that sets
    # can be custom-made by anyone)

    #'autodeclare': [
    #    ('correction', 'http://raw.github.com/proycon/folia/master/setdefinitions/spellingcorrection.foliaset.xml')
    #    ('entity', 'https://raw.githubusercontent.com/proycon/folia/master/setdefinitions/namedentities.foliaset.xml')
    #],

    # List of 2-tuples (tag,set) that specify what annotation types and with
    # what are required sets to be already present for each document that is
    # opened. This is more or less the opposite of autodeclare

    #'requiredeclaration': [
    #    ('correction', 'http://raw.github.com/proycon/folia/master/setdefinitions/spellingcorrection.foliaset.xml')
    #    ('entity', 'https://raw.githubusercontent.com/proycon/folia/master/setdefinitions/namedentities.foliaset.xml')
    #],

    #List of metadata keys (in  FoLiA's native metadata) to show in the
    # document index.
    #'metadataindex': ['status','language','title'],

    #Dictionary of metadata keys to lists of possible values, constrains the values in the metadata editor rather than offering a free-fill field. Example:
    #'metadataconstraints': {'language': ['fr','en','es'], 'status':['completed','inprogress']},

    #'searches': [{'query': 'SELECT entity WHERE annotatortype = "manual" FOR w RETURN target', 'label': "Highlight manually annotated entities"}]
    'converters': [
        { 'id': 'conllu2folia',
          'module': 'foliatools.conllu2folia',
          'function': 'flat_convert',
          'name': "CONLL-U",
          'parameter_help': 'Metadata. Set <em>"direction": "rtl"</em> for right-to left languages (JSON syntax without the envelopping curly braces)', #human readable help for parameters
          'parameter_default': '', #default parameter, JSON syntax without the envelopping {}
          'inputextensions': ['conllu','conll'],
        },
        { 'id': 'rst2folia',
          'module': 'foliatools.rst2folia',
          'function': 'flat_convert',
          'name': "ReStructuredText",
          'parameter_help': '', #human readable help for parameters
          'parameter_default': '', #default parameter, JSON syntax without the envelopping {}
          'inputextensions': ['rst'],
        },
    ]
},
}



##############################################################################
# DJANGO SETTINGS THAT NEED TO BE CHANGED (so edit me!)
#############################################################################

ADMINS = ( #Change to your contact details
    ("{{maintainer_name}}", "{{maintainer_mail}}"),
)

# Make this unique, and don't share it with anybody.
{% if django_secret_key is defined %}
SECRET_KEY = '{{django_secret_key}}'
{% else %}
# IMPORTANT!!!! GENERATE A NEW SECRET KEY !!!! The default one here is *NOT*
# secret as it's publicly disclosed in source!
# (Use for instance http://www.miniwebtool.com/django-secret-key-generator/)
SECRET_KEY = 'ki5^nfv02@1f1(+*#l_9GDi9h&cf^_lv6bs4j9^6mpr&(%o4zk'
{% endif %}

DEBUG = True #Set to False for production environments!!!!

{% if force_https %}
SECURE_PROXY_SSL_HEADER = ('HTTP_X_FORWARDED_PROTO', 'https')
{% endif %}


##############################################################################
# DJANGO SETTINGS FOR OPENID CONNECT AUTHENTICATION
#############################################################################

{% if oauth_client_id %}
OIDC = True

#note: The redirect url you register with your authorization provider should end in /oidc/callback/

AUTHENTICATION_BACKENDS = ( 'django.contrib.auth.backends.ModelBackend','mozilla_django_oidc.auth.OIDCAuthenticationBackend',)

OIDC_RP_CLIENT_ID = "{{ oauth_client_id }}" #As provided by your authorization provider, do not check this into public version control!!!
OIDC_RP_CLIENT_SECRET = "{{ oauth_client_secret }}" #As provided by your authorization provider, Do not check this into public version control!!!

OIDC_OP_AUTHORIZATION_ENDPOINT = "{{ oauth_auth_url }}"
OIDC_OP_TOKEN_ENDPOINT = "{{ oauth_token_url }}"
OIDC_OP_USER_ENDPOINT = "{{ oauth_userinfo_url }}"

OIDC_TOKEN_USE_BASIC_AUTH = True #Use client_secret_basic, if not enabled, client_secret_post will be default
{% if oauth_sign_algo %}
OIDC_RP_SIGN_ALGO = "{{ oauth_sign_algo }}" #should be HS256 or RS256
{% endif %}
{% if oauth_jwks_url %}
OIDC_OP_JWKS_ENDPOINT = "{{ oauth_jwks_url }}"
{% endif %}
{% if oauth_sign_key %}
OIDC_RD_IDP_SIGN_KEY = {{ oauth_sign_key | to_json }}
{% endif %}

{% else %}
OIDC = False
{% endif %}


##############################################################################
# DJANGO SETTINGS THAT NEED NOT BE CHANGED (but you may if you want to, do scroll through at least)
#############################################################################

# Feel free to tweak settings here, but the defaults should be enough

MANAGERS = ADMINS

# Hosts/domain names that are valid for this site; required if DEBUG is False
# See https://docs.djangoproject.com/en/1.5/ref/settings/#allowed-hosts
ALLOWED_HOSTS = ['localhost', '127.0.0.1', "{{lm_base_url|urlsplit('hostname')}}", "{{hostname}}"]


# Local time zone for this installation. Choices can be found here:
# http://en.wikipedia.org/wiki/List_of_tz_zones_by_name
# although not all choices may be available on all operating systems.
# In a Windows environment this must be set to your system time zone.
TIME_ZONE = 'Europe/Amsterdam'

# Language code for this installation. All choices can be found here:
# http://www.i18nguy.com/unicode/language-identifiers.html
LANGUAGE_CODE = 'en-us'

SITE_ID = 1

# If you set this to False, Django will make some optimizations so as not
# to load the internationalization machinery.
USE_I18N = False

# If you set this to False, Django will not format dates, numbers and
# calendars according to the current locale.
USE_L10N = True

# If you set this to False, Django will not use timezone-aware datetimes.
USE_TZ = True

# Absolute filesystem path to the directory that will hold user-uploaded files.
# Example: "/var/www/example.com/media/"
MEDIA_ROOT = BASE_DIR + 'usermedia/' #not used currently by FLAT

# URL that handles the media served from MEDIA_ROOT. Make sure to use a
# trailing slash.
# Examples: "http://example.com/media/", "http://media.example.com/"
MEDIA_URL = 'http://flat.science.ru.nl/usermedia/' #not used currently by FLAT

# Absolute path to the directory static files should be collected to.
# Don't put anything in this directory yourself; store your static files
# in apps' "static/" subdirectories and in STATICFILES_DIRS.
# Example: "/var/www/example.com/static/"
STATIC_ROOT = BASE_DIR + '/flat/static/'

#If you don't run at the document root of your webserver/virtual host, set BASE_PREFIX to your URL prefix (no trailing slash), e.g BASE_PREFIX = "/flat"
#leave empty in all other scenarios
BASE_PREFIX = '/flat'
if BASE_PREFIX: FORCE_SCRIPT_NAME = BASE_PREFIX #FLAT runs on the flat/ url prefix rather than the root

# URL prefix for static files.
# Example: "http://example.com/static/", "http://static.example.com/"
STATIC_URL = BASE_PREFIX + '/static/'

STYLE_ROOT = BASE_DIR + '/flat/style/'
STYLE_URL =  BASE_PREFIX + '/style/'

SCRIPT_ROOT = BASE_DIR + '/flat/script/'
SCRIPT_URL = BASE_PREFIX + '/script/'

# Additional locations of static files
STATICFILES_DIRS = (
    # Put strings here, like "/home/html/static" or "C:/www/django/static".
    # Always use forward slashes, even on Windows.
    # Don't forget to use absolute paths, not relative paths.
    BASE_DIR + '/flat/style/',
    BASE_DIR + '/flat/script/',
)


# List of finder classes that know how to find static files in
# various locations.
STATICFILES_FINDERS = (
    'django.contrib.staticfiles.finders.FileSystemFinder',
    'django.contrib.staticfiles.finders.AppDirectoriesFinder',
#    'django.contrib.staticfiles.finders.DefaultStorageFinder',
)

LOGIN_URL = BASE_PREFIX + "/login/"




# List of callables that know how to import templates from various sources.
TEMPLATE_LOADERS = (
    'django.template.loaders.filesystem.Loader',
    'django.template.loaders.app_directories.Loader',
#     'django.template.loaders.eggs.Loader',
)

MIDDLEWARE = (
    'django.middleware.common.CommonMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    # Uncomment the next line for simple clickjacking protection:
    # 'django.middleware.clickjacking.XFrameOptionsMiddleware',
)

ROOT_URLCONF = 'flat.urls'

# Python dotted path to the WSGI application used by Django's runserver.
WSGI_APPLICATION = 'flat.wsgi.application'

TEMPLATE_DIRS = [
    # Put strings here, like "/home/html/django_templates" or "C:/www/django/templates".
    # Always use forward slashes, even on Windows.
    # Don't forget to use absolute paths, not relative paths.
    BASE_DIR + 'flat/templates/'
]
for mode,_ in MODES:
    if os.path.isdir(BASE_DIR + '/flat/modes/' + mode + '/templates/'):
        TEMPLATE_DIRS.append(BASE_DIR + '/flat/modes/' + mode + '/templates/')

TEMPLATE_DIRS = tuple(TEMPLATE_DIRS)

if DJANGOVERSION[0] > 1 or DJANGOVERSION[1] >=8: #Django 1.8 and above
   TEMPLATES = [{
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'APP_DIRS': True,
        'DIRS': TEMPLATE_DIRS,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.debug',
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },]
   del TEMPLATE_DIRS
else:
    # List of callables that know how to import templates from various sources.
    TEMPLATE_LOADERS = (
        'django.template.loaders.filesystem.Loader',
        'django.template.loaders.app_directories.Loader',
    #     'django.template.loaders.eggs.Loader',
    )
    TEMPLATE_DEBUG = DEBUG


INSTALLED_APPS = [
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.sites',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    # Uncomment the next line to enable the admin:
    'django.contrib.admin',
    # Uncomment the next line to enable admin documentation:
    # 'django.contrib.admindocs',
    'flat.users'
]
if OIDC: INSTALLED_APPS.insert(1, 'mozilla_django_oidc')
for mode,_ in MODES:
    INSTALLED_APPS.append('flat.modes.' + mode)
INSTALLED_APPS = tuple(INSTALLED_APPS)

LOGIN_REDIRECT_URL = BASE_PREFIX + "/"
LOGOUT_REDIRECT_URL = BASE_PREFIX + "/"

SESSION_SERIALIZER = 'django.contrib.sessions.serializers.JSONSerializer'




# A sample logging configuration. The only tangible logging
# performed by this configuration is to send an email to
# the site admins on every HTTP 500 error when DEBUG=False.
# See http://docs.djangoproject.com/en/dev/topics/logging for
# more details on how to customize your logging configuration.
#LOGGING = {
#    'version': 1,
#    'disable_existing_loggers': False,
#    'filters': {
#        'require_debug_false': {
#            '()': 'django.utils.log.RequireDebugFalse'
#        }
#    },
#    'handlers': {
#        'mail_admins': {
#            'level': 'ERROR',
#            'filters': ['require_debug_false'],
#            'class': 'django.utils.log.AdminEmailHandler'
#        }
#    },
#    'loggers': {
#        'django.request': {
#            'handlers': ['mail_admins'],
#            'level': 'ERROR',
#            'propagate': True,
#        },
#    }
#}


# Now you can start FLAT as follows:

# $ export PYTHONPATH=/your/settings/path/
# $ export DJANGO_SETTINGS_MODULE=settings
# $ django-admin runserver

# But before the first time you run you will want to run the migrations and populate the
# database:

# $ export PYTHONPATH=/your/settings/path/
# $ export DJANGO_SETTINGS_MODULE=settings
# $ django-admin migrate --run-syncdb
# $ django-admin createsuperuser

# In any case, don't forget to start the document server too:

# $ foliadocserve -d /path/to/document/root -p 8080 --git
