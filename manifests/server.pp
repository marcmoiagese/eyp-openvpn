define openvpn::server(
                        $server_name                   = $name,
                        $port                          = undef,
                        $proto                         = undef,
                        $local                         = undef,
                        $user                          = 'openvpn',
                        $group                         = 'openvpn',
                        $dev                           = 'tun1',
                        $verbosity                     = '3',
                        $persist_key                   = false,
                        $persist_tun                   = false,
                        $chroot                        = undef,
                        $change_dir_to                 = undef,
                        $ping                          = undef,
                        $ping_restart                  = undef,
                        $push_ping                     = undef,
                        $push_ping_restart             = undef,
                        $client_to_client              = false,
                        $client_config_dir             = undef,
                        $topology                      = undef,
                        $max_clients                   = undef,
                        $server                        = undef,
                        $server_netmask                = '255.255.255.0',
                        $ifconfig_pool_persist_file    = undef,
                        $ifconfig_pool_persist_seconds = '0',
                        $easy_rsa                      = true,
                        $easy_rsa_fqdn_server          = 'openvpn.systemadmin.es',
                        $easy_rsa_organization         = 'systemadmin.es',
                        $easy_rsa_organization_unit    = 'EASY RSA',
                        $easy_rsa_req_email            = 'easy-rsa@systemadmin.es',
                        $easy_rsa_ca_expire            = '7500',
                        $easy_rsa_cert_expire          = '7500',
                        $easy_rsa_crl_days             = '7500',
                        $ca_file                       = undef,
                        $cert_file                     = undef,
                        $key_file                      = undef,
                        $dh_file                       = undef,
                        $crl_verify_file               = undef,
                        $manage_service                = true,
                        $manage_docker_service         = true,
                        $service_ensure                = 'running',
                        $service_enable                = true,
                      ) {
  Exec {
    path => '/usr/sbin:/usr/bin:/sbin:/bin',
  }

  include ::openvpn

  exec { "mkdir base ${server_name}":
    command => "mkdir -p ${openvpn::params::server_conf_dir}/${server_name}/",
    creates => "${openvpn::params::server_conf_dir}/${server_name}/",
    require => Class['::openvpn'],
  }

  exec { "mkdir -p ccd ${client_config_dir} ${server_name}":
    command => "mkdir -p ${openvpn::params::server_conf_dir}/${server_name}/${client_config_dir}",
    creates => "${openvpn::params::server_conf_dir}/${server_name}/${client_config_dir}",
    require => Class['::openvpn'],
  }

  concat { "${openvpn::params::server_conf_dir}/${server_name}.conf":
    ensure => 'present',
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
    notify => Openvpn::Server::Service["${openvpn::params::systemd_server_template_service}@${server_name}"],
  }

  concat::fragment { "base openvpn ${server_name}":
    target  => "${openvpn::params::server_conf_dir}/${server_name}.conf",
    order   => '00',
    content => template("${module_name}/server.erb"),
  }

  if($easy_rsa)
  {
    # cp -r /usr/share/easy-rsa /etc/openvpn/
    exec { "deploy easy-rsa from template ${server_name}":
      command => "cp -r /usr/share/easy-rsa ${openvpn::params::server_conf_dir}/${server_name}/",
      creates => "${openvpn::params::server_conf_dir}/${server_name}/easy-rsa",
      require => Exec["mkdir base ${server_name}"],
    }

    file { "${openvpn::params::server_conf_dir}/${server_name}/easy-rsa/3/vars":
      ensure  => 'present',
      owner   => 'root',
      group   => 'root',
      mode    => '0755',
      content => template("${module_name}/easyrsa/vars.erb"),
      require => Exec["deploy easy-rsa from template ${server_name}"],
    }

    exec { "init-pki ${server_name}":
      command => "${openvpn::params::server_conf_dir}/${server_name}/easy-rsa/3/easyrsa init-pki",
      cwd     => "${openvpn::params::server_conf_dir}/${server_name}/easy-rsa/3/",
      creates => "${openvpn::params::server_conf_dir}/${server_name}/easy-rsa/3/pki",
      require => File["${openvpn::params::server_conf_dir}/${server_name}/easy-rsa/3/vars"],
      timeout => 0,
      notify  => Openvpn::Server::Service["${openvpn::params::systemd_server_template_service}@${server_name}"],
    }

    #./easyrsa gen-dh
    exec { "gen-dh ${server_name}":
      command => "${openvpn::params::server_conf_dir}/${server_name}/easy-rsa/3/easyrsa gen-dh",
      cwd     => "${openvpn::params::server_conf_dir}/${server_name}/easy-rsa/3/",
      creates => "${openvpn::params::server_conf_dir}/${server_name}/easy-rsa/3/pki/dh.pem",
      require => Exec["init-pki ${server_name}"],
      timeout => 0,
      notify  => Openvpn::Server::Service["${openvpn::params::systemd_server_template_service}@${server_name}"],
    }

    exec { "build-ca ${server_name}":
      command     => "${openvpn::params::server_conf_dir}/${server_name}/easy-rsa/3/easyrsa build-ca nopass",
      environment => [ "EASYRSA_REQ_CN=EASY RSA ${server_name} CA" ],
      cwd         => "${openvpn::params::server_conf_dir}/${server_name}/easy-rsa/3/",
      creates     => "${openvpn::params::server_conf_dir}/${server_name}/easy-rsa/3/pki/ca.crt",
      require     => Exec["init-pki ${server_name}"],
      timeout     => 0,
      notify      => Openvpn::Server::Service["${openvpn::params::systemd_server_template_service}@${server_name}"],
    }

    exec { "gen-crl ${server_name}":
      command     => "${openvpn::params::server_conf_dir}/${server_name}/easy-rsa/3/easyrsa gen-crl",
      cwd         => "${openvpn::params::server_conf_dir}/${server_name}/easy-rsa/3/",
      require     => Exec["build-ca ${server_name}"],
      refreshonly => true,
      timeout     => 0,
      notify      => Openvpn::Server::Service["${openvpn::params::systemd_server_template_service}@${server_name}"],
    }

    #easy_rsa_fqdn_server
    exec { "build server ${server_name} / ${easy_rsa_fqdn_server}":
      command => "${openvpn::params::server_conf_dir}/${server_name}/easy-rsa/3/easyrsa build-server-full ${easy_rsa_fqdn_server} nopass",
      cwd     => "${openvpn::params::server_conf_dir}/${server_name}/easy-rsa/3/",
      creates => "${openvpn::params::server_conf_dir}/${server_name}/easy-rsa/3/pki/issued/${easy_rsa_fqdn_server}.crt",
      require => Exec["init-pki ${server_name}"],
      notify  => Exec["gen-crl ${server_name}"],
      timeout => 0,
    }


  }
  # TODO:
  # else { aqui validacions de ssl related *_file }

  openvpn::server::service { "${openvpn::params::systemd_server_template_service}@${server_name}":
    manage_service        => $manage_service,
    manage_docker_service => $manage_docker_service,
    service_ensure        => $service_ensure,
    service_enable        => $service_enable,
  }

}
