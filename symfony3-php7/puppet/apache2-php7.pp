
exec {'group-add-adm':
    command => '/usr/bin/sudo /usr/sbin/usermod -a -G adm vagrant'
}

exec {'php7-repo':
    command => '/usr/bin/sudo /usr/bin/add-apt-repository -y ppa:ondrej/php && /usr/bin/sudo /usr/bin/apt-get update'
}

exec {'apt-update':
    command => '/usr/bin/sudo /usr/bin/apt-get update'
}

package {['php7.0', 'php7.0-apcu', 'php7.0-cli', 'php7.0-common', 'php7.0-curl', 'php7.0-gd', 'php7.0-imagick', 'php7.0-intl', 'php7.0-json', 'php7.0-mbstring', 'php7.0-mcrypt', 'php7.0-mysql', 'php7.0-sqlite', 'php7.0-xdebug', 'php7.0-xml', 'php7.0-zip']:
    ensure => latest,
    require => Exec['php7-repo']
}

package {'apache2':
    ensure => latest,
    require => Package['php7.0']
}

package {'libapache2-mod-php7.0':
    ensure => latest,
    require => [Package['apache2'], Package['php7.0']]
}

package {'mysql-server':
    ensure => latest,
    require => Exec['apt-update']
}

package {'git':
    ensure => latest
}

service {'apache2':
  ensure => running,
  require => Package['apache2']
}

service {'mysql':
  ensure => running,
  require => Package['mysql-server']
}

file {'apache-envvars':
    path => '/etc/apache2/envvars',
    target => '/vagrant/puppet/assets/apache2-envvars',
    notify => Service['apache2'],
    require => Package['apache2']
}

file {'php7-apache':
    path => '/etc/php/7.0/apache2/php.ini',
    target => '/vagrant/puppet/assets/php7-apache.ini',
    notify => Service['apache2'],
    require => Package['php7.0']
}

file {'php7-cli':
    path => '/etc/php/7.0/cli/php.ini',
    target => '/vagrant/puppet/assets/php7-cli.ini',
    require => Package['php7.0-cli']
}

exec {'apache-mod-rewrite':
    command => '/usr/sbin/a2enmod rewrite',
    notify => Service['apache2'],
    require => Package['apache2']
}

exec {'create-db':
    command => '/usr/bin/mysql -u root < /vagrant/puppet/assets/symfony.sql',
    require => [Package['mysql-server'], Service['mysql']]
}

exec {'apache-disable-default-site':
    command => '/usr/sbin/a2dissite 000-default',
    notify => Service['apache2'],
    require => Package['apache2']
}

file {'apache-sf-site':
    path => '/etc/apache2/sites-enabled/sf.conf',
    target => '/vagrant/puppet/assets/apache-sf.conf',
    notify => Service['apache2'],
    require => Package['apache2']
}

exec {'phpmyadmin-fetch':
    command => '/usr/bin/wget -q https://files.phpmyadmin.net/phpMyAdmin/4.6.3/phpMyAdmin-4.6.3-all-languages.tar.gz',
    creates => '/home/vagrant/phpMyAdmin-4.6.3-all-languages.tar.gz'
}

exec {'phpmyadmin-extract':
    command => '/bin/tar -zxvf phpMyAdmin-4.6.3-all-languages.tar.gz',
    creates => '/home/vagrant/phpMyAdmin-4.6.3-all-languages',
    require => Exec['phpmyadmin-fetch']
}

file {'phpmyadmin-conf':
    path => '/home/vagrant/phpMyAdmin-4.6.3-all-languages/config.inc.php',
    source => '/vagrant/puppet/assets/phpmyadmin-config.inc.php',
    require => Exec['phpmyadmin-extract']
}

file {'apache-phpmyadmin':
    path => '/etc/apache2/conf-enabled/phpmyadmin.conf',
    ensure => link,
    target => '/vagrant/puppet/assets/apache-phpmyadmin.conf',
    notify => Service['apache2'],
    require => Package['apache2']
}

file {'symfony-config':
    source => '/vagrant/deploy/parameters-dev.yml',
    path => '/vagrant/app/config/parameters.yml',
    ensure => present
}

exec {'swap-setup':
    command => '/usr/bin/sudo /bin/sh /vagrant/puppet/assets/swap.sh'
}

exec {'composer-setup':
    command => '/usr/bin/sudo /bin/sh /vagrant/puppet/assets/composer-setup.sh',
    require => Package['php7.0', 'php7.0-apcu', 'php7.0-cli', 'php7.0-common', 'php7.0-curl', 'php7.0-gd', 'php7.0-imagick', 'php7.0-intl', 'php7.0-json', 'php7.0-mbstring', 'php7.0-mcrypt', 'php7.0-mysql', 'php7.0-sqlite', 'php7.0-xdebug', 'php7.0-xml', 'php7.0-zip']
}

exec {'composer-install-deps':
    group => vagrant,
    user => vagrant,
    environment => ["HOME=/home/vagrant"],
    cwd => '/vagrant',
    command => '/usr/local/bin/composer install',
    timeout => 0,
    require => [Exec['composer-setup'], File['symfony-config'], Package['git'], Package['php7.0-zip'], Exec['swap-setup']]
}

exec {'symfony-deploy':
  command => '/bin/sh deploy/deploy-dev.sh',
  cwd => '/vagrant',
  require => [Package['php7.0-cli'], Exec['create-db'], Exec['composer-install-deps']]
}
