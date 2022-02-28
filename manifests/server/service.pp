define openvpn::server::service (
                                  $manage_service        = true,
                                  $manage_docker_service = true,
                                  $service_ensure        = 'running',
                                  $service_enable        = true,
                                  $service_name          = $name,
                                ) {

  $is_docker_container_var=getvar('::eyp_docker_iscontainer')
  $is_docker_container=str2bool($is_docker_container_var)

  if( $is_docker_container==false or
      $manage_docker_service)
  {
    if($manage_service)
    {
      service { $service_name:
        ensure => $service_ensure,
        enable => $service_enable,
      }
    }
  }
}
