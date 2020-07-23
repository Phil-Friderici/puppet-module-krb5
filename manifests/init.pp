# Manage the kerberos config file and client packages
class krb5 (
    $logging_default      = 'FILE:/var/log/krb5libs.log',
    $logging_kdc          = 'FILE:/var/log/krb5kdc.log',
    $logging_admin_server = 'FILE:/var/log/kadmind.log',
    $logging_krb524d      = undef,
    $default_realm        = undef,
    $dns_lookup_realm     = undef,
    $dns_lookup_kdc       = undef,
    $ticket_lifetime      = undef,
    $default_ccache_name  = undef,
    $default_keytab_name  = undef,
    $forwardable          = undef,
    $allow_weak_crypto    = undef,
    $proxiable            = undef,
    $realms               = undef,
    $appdefaults          = undef,
    $domain_realm         = undef,
    $rdns                 = undef,
    $default_tkt_enctypes = undef,
    $default_tgs_enctypes = undef,
    $package              = [],
    $package_adminfile    = undef,
    $package_provider     = undef,
    $package_source       = undef,
    $krb5conf_file        = '/etc/krb5.conf',
    $krb5conf_ensure      = 'present',
    $krb5conf_owner       = 'root',
    $krb5conf_group       = 'root',
    $krb5conf_mode        = '0644',
    $krb5key_link_target  = undef,
) {

  if $package == [] {
    case $::osfamily {
      'RedHat': {
        $package_array = [ 'krb5-libs', 'krb5-workstation' ]
      }
      'Suse': {
        $package_array = [ 'krb5', 'krb5-client' ]
      }
      'Solaris': {
        case $::kernelrelease {
          '5.10': {
            $package_array = [ 'SUNWkrbr', 'SUNWkrbu' ]
          }
          '5.11': {
            $package_array = [ 'pkg:/service/security/kerberos-5' ]
          }
          default: {
            fail("krb5 only supports default package names for Solaris 5.10 and 5.11. Detected kernelrelease is <${::kernelrelease}>. Please specify package name with the \$package variable.")
          }
        }
      }
      'Debian': {
        $package_array = [ 'krb5-user' ]
      }
      default: {
        fail("krb5 only supports default package names for Debian, RedHat, Suse and Solaris. Detected osfamily is <${::osfamily}>. Please specify package name with the \$package variable.")
      }
    }
  }
  else {
    case type3x($package) {
      'array':  { $package_array = $package }
      'string': { $package_array = [ $package ] }
      default:  { fail('krb5::package is not an array nor a string.') }
    }
  }

  if $package_adminfile != undef {
    Package {
      adminfile => $package_adminfile,
    }
  }

  if $package_provider != undef {
    Package {
      provider => $package_provider,
    }
  }

  if $package_source != undef {
    Package {
      source => $package_source,
    }
  }

  package{ $package_array:
    ensure  => present,
  }

  file{ 'krb5conf':
    ensure  => $krb5conf_ensure,
    path    => $krb5conf_file,
    owner   => $krb5conf_owner,
    group   => $krb5conf_group,
    mode    => $krb5conf_mode,
    content => template('krb5/krb5.conf.erb'),
  }

  if $::osfamily == 'Solaris' {
    file { 'krb5directory' :
      ensure => directory,
      path   => '/etc/krb5',
      owner  => $krb5conf_owner,
      group  => $krb5conf_group,
    }

    file { 'krb5link' :
      ensure  => link,
      path    => '/etc/krb5/krb5.conf',
      target  => $krb5conf_file,
      require => File['krb5directory'],
    }
  }

  if $krb5key_link_target != undef {
    validate_absolute_path($krb5key_link_target)

    file { 'krb5keytab_file':
      ensure => link,
      path   => '/etc/krb5.keytab',
      target => $krb5key_link_target,
    }
  }
}
