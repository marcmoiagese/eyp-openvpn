class openvpn (
                $manage_package        = true,
                $package_ensure        = 'installed',
              ) inherits openvpn::params{

  class { '::openvpn::install': }
  -> Class['::openvpn']
}
