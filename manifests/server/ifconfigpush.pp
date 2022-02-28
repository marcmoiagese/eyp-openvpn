define openvpn::server::ifconfigpush(
                                      $server_name,
                                      $ipaddr,
                                      $client_config_dir = 'ccd',
                                      $fqdn              = $name,
                                      $ensure            = 'present',
                                      $netmask           = '255.255.255.0',
                                      $order             = '00',
                                    ) {
  include ::openvpn

  if(!defined(Concat["${openvpn::params::server_conf_dir}/${server_name}/${client_config_dir}/${fqdn}"]))
  {
    concat { "${openvpn::params::server_conf_dir}/${server_name}/${client_config_dir}/${fqdn}":
      ensure  => 'present',
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      notify  => Openvpn::Server::Service["openvpn-server@${server_name}"],
      require => Exec["mkdir -p ccd ${client_config_dir} ${server_name}"]
    }
  }

  if($ensure=='present')
  {
    concat::fragment { "ifconfig push ${server_name} ${client_config_dir} ${fqdn}":
      target  => "${openvpn::params::server_conf_dir}/${server_name}/${client_config_dir}/${fqdn}",
      order   => $order,
      content => template("${module_name}/server/ifconfigpush.erb"),
    }
  }
}
