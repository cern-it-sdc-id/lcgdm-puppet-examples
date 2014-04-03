$token_password = "TOKEN_PASSWORD"
$mysql_root_pass = "mypass"
$db_user = "dpmmgr"
$db_pass = "mypass"
$db_host = "remotehost"
$domain  = "mydomain"
$localdomain = "${::fqdn}"
$volist = ["dteam", "atlas"]
$disk_nodes = "${::fqdn}"
$xrootd_sharedkey = "A32TO64CHARACTERKEY"
$debug = false

 firewall{"050 allow DPM":
 {
    state  => "NEW",
    proto  => "tcp",
    dport  => "5010",
    action => "accept"
  }
  firewall{"050 allow DPM":
    state  => "NEW",
    proto  => "tcp",
    dport  => "5015",
    action => "accept"
  }

  Class[Lcgdm::Dpm::Service] -> Class[Dmlite::Plugins::Adapter::Install]
  Class[Dmlite::Plugins::Adapter::Install] ~> Class[Dmlite::Dav::Service]
  Class[Dmlite::Plugins::Mysql::Install] ~> Class[Dmlite::Dav::Service]
  Class[Dmlite::Plugins::Adapter::Install] ~> Class[Dmlite::Gridftp]
  Class[Dmlite::Plugins::Mysql::Install] ~> Class[Dmlite::Gridftp]
  Class[Dmlite::Plugins::Adapter::Install] ~> Class[Dmlite::Srm]
  Class[Dmlite::Plugins::Mysql::Install] ~> Class[Dmlite::Srm]

  Class[Lcgdm::Ns::Service] -> Class[Lcgdm::Dpm::Service]
  Class[Lcgdm::Ns::Service] -> Class[Lcgdm::Ns::Client]
  Class[Lcgdm::Dpm::Service] -> Lcgdm::Ns::Domain <| |>
  Lcgdm::Ns::Domain <| |> -> Lcgdm::Ns::Vo <| |>
  Class[Mysql::Server] -> Class[Lcgdm::Ns::Install]


  #
  # Nameserver client and server configuration.
  #
  class{"lcgdm::ns":
    dbuser   => "${db_user}",
    dbpass   => "${db_pass}",
    dbhost   => "${db_host}",
    dbmanage => false,
  }

  #
  # DPM daemon configuration.
  #
  class{"lcgdm::dpm":
    dbuser   => "${db_user}",
    dbpass   => "${db_pass}",
    dbhost   => "${db_host}",
    dbmanage => false,

  }

  #
  # Create path for domain and VOs to be enabled.
  #
  lcgdm::ns::domain{$domain:}
  lcgdm::ns::vo{$volist:
    domain => $domain,
  }

  #
  # dmlite configuration.
  #
  class{"dmlite::head":
    token_password => "${token_password}",
    mysql_username => "${db_user}",
    mysql_password => "${db_pass}",
    mysql_host     => "${db_host}",
    adminuser      => undef,
  }


  #
  # shift.conf setup.
  #
  lcgdm::shift::trust_value{
    "DPM TRUST":
      component => "DPM",
      host      => "${disk_nodes}"
    "DPNS TRUST":
      component => "DPNS",
      host      => "${disk_nodes}"
    "RFIO TRUST":
      component => "RFIOD",
      host      => "${disk_nodes}"
      all       => true;
  }
  lcgdm::shift::protocol{"PROTOCOLS":
    component => "DPM",
    proto     => "rfio gsiftp http https xroot"
  }

  #
  # VOMS configuration (same VOs as above).
  #
  class{"voms::alice":}
  class{"voms::atlas":}
  class{"voms::cms":}
  class{"voms::dteam":}
  class{"voms::lhcb":}

  #
  # Gridmapfile configuration.
  #
  class{"lcgdm::mkgridmap::install":}
  $groupmap = {
    "vomss://voms.hellasgrid.gr:8443/voms/dteam?/dteam/Role=lcgadmin"   => "dteam",
    "vomss://voms.hellasgrid.gr:8443/voms/dteam?/dteam/Role=production" => "dteam",
    "vomss://voms.hellasgrid.gr:8443/voms/dteam?/dteam"                 => "dteam",
    "vomss://voms.cern.ch:8443/voms/atlas?/atlas/Role=lcgadmin"         => "atlas",
    "vomss://voms.cern.ch:8443/voms/atlas?/atlas/Role=production"       => "atlas",
    "vomss://voms.cern.ch:8443/voms/atlas?/atlas"                       => "atlas"
  }
  lcgdm::mkgridmap::file {"lcgdm-mkgridmap":
    configfile   => "/etc/lcgdm-mkgridmap.conf",
    mapfile      => "/etc/lcgdm-mapfile",
    localmapfile => "/etc/lcgdm-mapfile-local",
    logfile      => "/var/log/lcgdm-mkgridmap.log",
    groupmap     => $groupmap,
    localmap     => {"nobody" => "nogroup"},
  }

  #
  # dmlite frontends configuration.
  #
  class{"dmlite::dav::config":
    ns_flags   => "Write RemoteCopy",
    disk_flags => "Write RemoteCopy"
  }
  class{"dmlite::dav":}

  class{"dmlite::srm":}
  class{"dmlite::gridftp":
    dpmhost => "${::fqdn}"
  }

  class{"xrootd::config":
    xrootd_user  => 'dpmmgr',
    xrootd_group => 'dpmmgr'
  }

  $nodetype = [ 'head' ]

  class{"dmlite::xrootd":
    nodetype             => $nodetype,
    domain               => "${disk_nodes}"
    dpm_xrootd_sharedkey => "${xrootd_sharedkey}"
  }

  #
  # dmlite shell configuration.
  #
  class{"dmlite::shell":}

}
