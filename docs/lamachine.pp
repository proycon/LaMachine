# $Id: lamachine.pp 95902 2018-06-08 08:43:45Z lbiemans $
# $URL: https://svn.uvt.nl/its-unix/systems/maroon/etc/puppet/lamachine.pp $

# apache met wat standaardmodules
class apache2 {
  package {
    'apache2':                 ensure => installed;
  }

  service { 'apache2':
    enable     => true,
    hasrestart => true,
    hasstatus  => true,
    restart    => 'exec service apache2 reload',
  }

  file {
    default:
      ensure => link,
      notify => Service['apache2'];
    '/etc/apache2/mods-enabled/ssl.load': target => '../mods-available/ssl.load';
    '/etc/apache2/mods-enabled/ssl.conf': target => '../mods-available/ssl.conf';
    '/etc/apache2/mods-enabled/socache_shmcb.load': target => '../mods-available/socache_shmcb.load';
    '/etc/apache2/mods-enabled/expires.load': target => '../mods-available/expires.load';
    '/etc/apache2/mods-enabled/http2.load': target => '../mods-available/http2.load';
    '/etc/apache2/mods-enabled/headers.load': target => '../mods-available/headers.load';
    '/etc/apache2/mods-enabled/proxy.load': target => '../mods-available/proxy.load';
    '/etc/apache2/mods-enabled/proxy.conf': target => '../mods-available/proxy.conf';
    '/etc/apache2/mods-enabled/proxy_http.load': target => '../mods-available/proxy_http.load';
    '/etc/apache2/mods-enabled/rewrite.load': target => '../mods-available/rewrite.load';
    '/etc/apache2/mods-enabled/proxy_wstunnel.load': target => '../mods-available/proxy_wstunnel.load';
    '/etc/apache2/mods-enabled/proxy_uwsgi.load': target => '../mods-available/proxy_uwsgi.load';
    '/etc/apache2/mods-enabled/access_compat.load': ensure => absent;
    '/etc/apache2/sites-enabled/lamachine.conf': target => '../sites-available/lamachine.conf';
    '/etc/apache2/sites-enabled/000-default.conf': ensure => absent;
  }
}

# Python packages en user

class python {
  group { 'pip':
    ensure => present,
    system => true,
    gid    => 500,
  }

  user { 'pip':
    ensure  => present,
    comment => 'pip install user ',
    home    => '/var/lib/pip',
    shell   => '/bin/bash',
    system  => true,
    uid     => 500,
    gid     => 'pip',
  }

  file {
    default:
      ensure  => directory,
      mode    => '2755',
      owner   => 'pip',
      group   => 'pip',
      require => User['pip'];
    '/opt/pip':;
    '/opt/npm':;
    '/var/lib/pip':;
    '/var/lib/pip/.pip':;
    '/var/lib/pip/.local': ensure => absent, force => true;
  }

  file {
    '/usr/local/lib/python3.5/dist-packages':
    ensure => link,
    target => 'site-packages',
    force  => true,
  }

  exec { 'Check if there is a pip upgrade available':
    path    => ['/usr/bin', '/usr/sbin'],
    command => 'pip3 install --system --prefix=/opt/pip -U pip',
    user    => 'pip',
  }
}

# lamachine user en group

class lamachine {
  group { 'lamachine':
    ensure => present,
    system => true,
    gid    => 501,
  }

  user { 'lamachine':
    ensure  => present,
    comment => 'lamachine user',
    home    => '/var/lib/lamachine',
    shell   => '/usr/sbin/nologin',
    system  => true,
    uid     => 501,
    gid     => 'lamachine',
  }

  file {
    default:
      ensure  => directory,
      mode    => '2755',
      owner   => 'lamachine',
      group   => 'lamachine',
      require => User['lamachine'];
    '/var/lib/lamachine':
      owner  => 'lamachine';
  }
}

# Packages installeren
class packages {
  package {
    'python3-setuptools':           ensure => installed;
    'python3-dev':                  ensure => installed;
    'python-setuptools':            ensure => installed;
    'python-dev':                   ensure => installed;
    'python3-pip':                  ensure => installed;
    'python-pip':                   ensure => installed;
    'python-virtualenv':            ensure => installed;
    'virtualenv':                   ensure => installed;
    'automake':                     ensure => installed;
    'dh-autoreconf':                ensure => installed;
    'autoconf-archive':             ensure => installed;
    'pkg-config':                   ensure => installed;
    'git':                          ensure => installed;
    'zlib1g-dev':                   ensure => installed;
    'libbz2-dev':                   ensure => installed;
    'build-essential':              ensure => installed;
    'libtar':                       ensure => installed;
    'libtar-dev':                   ensure => installed;
    'libboost-regex-dev':           ensure => installed;
    'libexttextcat-data':           ensure => installed;
    'libexttextcat-dev':            ensure => installed;
    'libxml2-dev':                  ensure => installed;
    'libboost-python-dev':          ensure => installed;
    'oracle-java8-jre':             ensure => installed;
    'libapache2-mod-proxy-uwsgi':   ensure => installed;
    'poppler-utils':                ensure => installed;
    'imagemagick':                  ensure => installed;
    'tesseract-ocr':                ensure => installed;
    'tesseract-ocr-nld':            ensure => installed;
    'tesseract-ocr-fra':            ensure => installed;
    'tesseract-ocr-eng':            ensure => installed;
    'tesseract-ocr-deu':            ensure => installed;
    'tesseract-ocr-deu-frak':       ensure => installed;
  }
}
