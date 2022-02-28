# client
# dev tun
#
# comp-lzo
# proto tcp
#
# persist-key
# persist-tun
#
# remote vpn.systemadmin.es 1184
#
# tls-client
#
# ns-cert-type server
#
# <ca>
# ...
# </ca>
#
# <cert>
# ...
# </cert>
#
# <key>
# ...
# </key>
define openvpn::client(
                        $ca_source,
                        $cert_source,
                        $key_source,
                        $client_name           = $name,
                        $remote                = $name,
                        $remote_port           = '1184',
                        $manage_service        = true,
                        $manage_docker_service = true,
                        $service_ensure        = 'running',
                        $service_enable        = true,
                        $dev                   = 'tun',
                        $proto                 = undef,
                        $persist_key           = false,
                        $persist_tun           = false,
                        $tls_client            = false,
                        $comp_lzo              = false,
                        $ns_cert_type          = undef,
                      ) {
  Exec {
    path => '/usr/sbin:/usr/bin:/sbin:/bin',
  }

  include ::openvpn

  exec { "mkdir base ${client_name}":
    command => "mkdir -p ${openvpn::params::client_conf_dir}/${client_name}/",
    creates => "${openvpn::params::client_conf_dir}/${client_name}/",
    require => Class['::openvpn'],
  }

  file { "${openvpn::params::client_conf_dir}/${client_name}/ca.pem":
    ensure  => 'present',
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    source  => $ca_source,
    require => Exec["mkdir base ${client_name}"],
  }

  file { "${openvpn::params::client_conf_dir}/${client_name}/cert.pem":
    ensure  => 'present',
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    source  => $cert_source,
    require => Exec["mkdir base ${client_name}"],
  }

  file { "${openvpn::params::client_conf_dir}/${client_name}/key.pem":
    ensure  => 'present',
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    source  => $key_source,
    require => Exec["mkdir base ${client_name}"],
  }

  concat { "${openvpn::params::client_conf_dir}/${client_name}.conf":
    ensure => 'present',
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
    notify => Openvpn::Client::Service["${openvpn::params::systemd_client_template_service}@${client_name}"],
  }

  concat::fragment { "base openvpn ${client_name}":
    target  => "${openvpn::params::client_conf_dir}/${client_name}.conf",
    order   => '00',
    content => template("${module_name}/client.erb"),
  }

  openvpn::client::service { "${openvpn::params::systemd_client_template_service}@${client_name}":
    manage_service        => $manage_service,
    manage_docker_service => $manage_docker_service,
    service_ensure        => $service_ensure,
    service_enable        => $service_enable,
  }
}
