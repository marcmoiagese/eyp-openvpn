class openvpn::install inherits openvpn {

  if($openvpn::params::include_epel)
  {
    include ::epel

    Package[$openvpn::params::package_name] {
      require => Class['::epel'],
    }
  }

  if($openvpn::manage_package)
  {
    package { $openvpn::params::package_name:
      ensure => $openvpn::package_ensure,
    }
  }

}
