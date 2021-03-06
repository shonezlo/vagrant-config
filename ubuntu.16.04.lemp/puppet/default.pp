
exec {'apt-update':
    command => '/usr/bin/sudo /usr/bin/apt update'
}

package {['nginx', 'php7.0', 'php7.0-mysql', 'php7.0-gd', 'php7.0-bz2', 'php7.0-xml', 'php7.0-cli', 'php7.0-phpdbg', 'php7.0-common', 'php7.0-intl', 'php7.0-curl', 'php7.0-json', 'php7.0-readline', 'php7.0-zip', 'php7.0-mbstring', 'php7.0-mcrypt', 'php-xdebug', 'php-common', 'php-fpm']:
    ensure => latest,
    require => Exec['apt-update']
}

service{'nginx':
    ensure => running,
    require => Package['nginx']
}

service{'php-fpm':
    name => 'php7.0-fpm',
    ensure => running,
    require => Package['php-fpm']
}

package {'mysql-server':
    ensure => latest,
    require => Exec['apt-update']
}

package {'git':
    ensure => latest
}

service {'mysql':
  ensure => running,
  require => Package['mysql-server']
}

file {'phpconf-fpm':
    path => '/etc/php/7.0/fpm/php.ini',
    source => '/vagrant/puppet/assets/php7-fpm.ini',
    notify => Service['php-fpm'],
    require => Package['php7.0', 'php-fpm']
}

file {'phpconf-cli':
    path => '/etc/php/7.0/cli/php.ini',
    source => '/vagrant/puppet/assets/php7-cli.ini',
    require => Package['php7.0-cli']
}

exec {'create-db':
    command => '/usr/bin/mysql -u root < /vagrant/puppet/assets/database.sql',
    require => [Package['mysql-server'], Service['mysql']]
}

file {'/etc/nginx/sites-enabled/default':
    ensure => 'absent',
    require => Package['nginx']
}

file {'nginx-dev-site':
    path => '/etc/nginx/sites-enabled/dev',
    source => '/vagrant/puppet/assets/nginx-dev.conf',
    notify => Service['nginx'],
    require => [Package['nginx', 'php-fpm'], File['/etc/nginx/sites-enabled/default']]
}

exec {'phpmyadmin-fetch':
    command => '/usr/bin/wget -q https://files.phpmyadmin.net/phpMyAdmin/4.6.5.2/phpMyAdmin-4.6.5.2-all-languages.tar.gz',
    creates => '/home/ubuntu/phpMyAdmin-4.6.5.2-all-languages.tar.gz'
}

exec {'phpmyadmin-extract':
    command => '/bin/tar -zxvf phpMyAdmin-4.6.5.2-all-languages.tar.gz && /bin/mv phpMyAdmin-4.6.5.2-all-languages phpmyadmin',
    creates => '/home/ubuntu/phpmyadmin',
    require => Exec['phpmyadmin-fetch']
}

file {'phpmyadmin-conf':
    path => '/home/ubuntu/phpmyadmin/config.inc.php',
    source => '/vagrant/puppet/assets/phpmyadmin-config.inc.php',
    require => Exec['phpmyadmin-extract']
}

exec {'swap-setup':
    command => '/usr/bin/sudo /bin/sh /vagrant/puppet/assets/swap.sh'
}