# [root@tachi 3]# ./easyrsa build-client-full croscat.systemadmin.es nopass
# Generating a 2048 bit RSA private key
# ..........................+++
# ...................................................................+++
# writing new private key to '/etc/openvpn/server/tuntcp/easy-rsa/3/pki/private/croscat.systemadmin.es.key.6jqeEsvAZJ'
# -----
# Using configuration from /etc/openvpn/server/tuntcp/easy-rsa/3/openssl-1.0.cnf
# Check that the request matches the signature
# Signature ok
# The Subject's Distinguished Name is as follows
# commonName            :ASN.1 12:'croscat.systemadmin.es'
# Certificate is to be certified until Mar  2 15:09:57 2040 GMT (7500 days)
#
# Write out database with 1 new entries
# Data Base Updated
# [root@tachi 3]#
define openvpn::server::clientcert(
                                    $server_name,
                                    $ensure = 'present',
                                    $fqdn   = $name,
                                  ) {
  include ::openvpn

  if($ensure=='present')
  {
    exec { "build-client ${fqdn} ${server_name}":
      command => "${openvpn::params::server_conf_dir}/${server_name}/easy-rsa/3/easyrsa build-client-full ${fqdn} nopass",
      cwd     => "${openvpn::params::server_conf_dir}/${server_name}/easy-rsa/3/",
      creates => "${openvpn::params::server_conf_dir}/${server_name}/easy-rsa/3/pki/issued/${fqdn}.crt",
      require => Exec["build-ca ${server_name}"],
      timeout => 0,
    }
  }
  else
  {
    fail('unimplemented')
  }

}
