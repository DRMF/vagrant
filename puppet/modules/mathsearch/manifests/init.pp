# == Class: mathsearch
#
# Module for the extension math search.
#
# === Parameters
#
# [*par*]
#   desc
#
# === Examples
#
#  class { 'mathsearch':
#  }
#
class mathsearch(
) {
    include role::math
    include role::geshi
    include role::cirrussearch

    exec { "import test data":
        command     => "/usr/bin/php importDump.php /vagrant/puppet/modules/mathsearch/files/sample.xml.bz2  && touch /home/vagrant/.sample-created",
        creates     => "/home/vagrant/.sample-created",
        cwd         => "/vagrant/mediawiki/maintenance/",
        require     =>  Class['::mediawiki'],
    }

    exec { "switch to dev branch of math":
        command     => "git checkout -b dev origin/dev",
        onlyif      => "git status | grep -c 'master'",
        cwd         => "/vagrant/mediawiki/extensions/Math",
        require     => [ Package['git'], Mediawiki::Extension['Math'] ],
        environment => 'HOME=/home/vagrant',
        timeout     => 0,
    }

    exec { 'compile texvccheck':
        command => 'make',
        cwd     => '/vagrant/mediawiki/extensions/Math/texvccheck',
        creates => '/vagrant/mediawiki/extensions/Math/texvccheck/texvccheck',
        require => Package['mediawiki-math', 'ocaml-native-compilers'],
    }

    mediawiki::extension { 'MathSearch':
        needs_update => true,
        settings => template('mathsearch/MathSearch.php.erb'),
    }

    exec { "build CirrusSearch search index":
        command     => "php ./maintenance/updateSearchIndexConfig.php && touch .indexed",
        creates     => "/vagrant/mediawiki/extensions/CirrusSearch/.indexed",
        cwd         => "/vagrant/mediawiki/extensions/CirrusSearch",
        require     =>  Mediawiki::Extension['CirrusSearch'],
    }

    exec { 'install ReRenderMath':
        cwd     => "/vagrant/mediawiki/extensions/MathSearch/maintenance/",
        command => "/usr/bin/php UpdateMath.php && /usr/bin/php CreateMathIndex.php /vagrant/mediawiki/extensions/MathSearch/mws/data/wiki --mwsns=mws: ",
        creates => '/vagrant/mediawiki/extensions/MathSearch/mws/data/wiki/math000000000000.xml',  
    }

    exec { 'install mwsd':
        cwd     => "/vagrant/mediawiki/extensions/MathSearch/mws",
        command => '/bin/bash install.sh',
        creates => '/etc/init.d/restd_wiki',
        user    => 'root',
        require  => Mediawiki::Extension['MathSearch'],       
    }

}
