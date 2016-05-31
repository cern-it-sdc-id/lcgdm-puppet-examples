#
# This is an example configuration for the LFC service.
#
# You can check the puppet modules 'lcgdm' and 'dmlite' for any additional options available.
# !! Please replace the placeholders for usernames and passwords !!
#

#
# The standard variables are collected here:
#
$mysql_root_pass = "PASS"
$db_user = "dpmmgr"
$db_pass = "MYSQLPASS"
$localdomain = "cern.ch"
$volist = ["dteam", "atlas", "lhcb"]
$debug = false


Class[mysql::server] -> Class[lcgdm::ns::service]
Class[lcgdm::ns::service] -> Class[lcgdm::ns::client]
Lcgdm::Ns::Domain <| |> -> Lcgdm::Ns::Vo <| |>
Class[dmlite::plugins::adapter::install] ~> Class[dmlite::dav::lfc]

#
# The firewall configuration
#
firewall{"050 allow http and https":
  proto  => "tcp",
  dport  => [80, 443],
  action => "accept"
}
firewall{"050 allow LFC clients":
  state  => "NEW",
  proto  => "tcp",
  dport  => "5010",
  action => "accept"
}
firewall{"050 allow LFC DLI clients":
  state  => "NEW",
  proto  => "tcp",
  dport  => "8085",
  action => "accept"
}
#
# MySQL server setup - disable if it is not local
#
class{"mysql::server":
  service_enabled => true,
  root_password   => "${mysql_root_pass}"
}

#
# lcgdm configuration
#
class{"lcgdm::base":
  cert    => "lfccert.pem",
  certkey => "lfckey.pem",
  user    => "lfcmgr"
}

#
# Nameserver client and server configuration.
#
class{"lcgdm::ns":
  flavor   => "lfc",
  dbflavor => "mysql",
  dbuser   => "${db_user}",
  dbpass   => "${db_pass}",
}

#
# dmlite plugins configuration.
#
class{"dmlite::lfc":
  dbflavor        => "mysql",
  dbuser          => "${db_user}",
  dbpass          => "${db_pass}",
}
class{"dmlite::plugins::librarian":}

#
# Create path for VOs to be enabled.
#
lcgdm::ns::domain{$volist:}

#
# Frontends based on dmlite.
#
class{"dmlite::dav::lfc":}

#
# VOMS configuration (same VOs as above).
#
class{"voms::dteam":}
class{"voms::atlas":}

#
# Gridmapfile configuration.
#
$groupmap = {
  "vomss://voms.hellasgrid.gr:8443/voms/dteam?/dteam"                 => "dteam",
  "vomss://voms2.cern.ch:8443/voms/atlas?/atlas"                      => "atlas",
  "vomss://lcg-voms2.cern.ch:8443/voms/atlas?/atlas"                  => "atlas"
}
lcgdm::mkgridmap::file {"lcgdm-mkgridmap":
  configfile   => "/etc/lcgdm-mkgridmap.conf",
  mapfile      => "/etc/lcgdm-mapfile",
  localmapfile => "/etc/lcgdm-mapfile-local",
  logfile      => "/var/log/lcgdm-mkgridmap.log",
  groupmap     => $groupmap,
  localmap     => {"nobody" => "nogroup"}
}

lcgdm::shift::trust_value{"lfc-localhost":
  component => "LFC",
  host      => "*"
}
