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

    exec { "switch to dev branch of math":
        command     => "git checkout -b dev origin/dev",
        onlyif      => "git status | grep -c 'master'",
        creates     => "${directory}/.git",
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
}
