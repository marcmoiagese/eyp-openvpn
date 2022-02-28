openvpn::server { 'tuntcp':
  proto                      => 'tcp',
  local                      => '127.0.0.1',
  client_to_client           => true,
  topology                   => 'subnet',
  server                     => '172.16.102.0',
  ifconfig_pool_persist_file => 'ipp.txt',
  ping                       => '10',
  ping_restart               => '120',
  push_ping                  => '10',
  push_ping_restart          => '60',
  max_clients                => '15',
  persist_key                => true,
  persist_tun                => true,
}

openvpn::server::clientcert { 'croscat.systemadmin.es':
  server_name => 'tuntcp',
}
