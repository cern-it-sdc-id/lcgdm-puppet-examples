#
# This is an example configuration for a DPM Head Node when upgrading an existing installation configured with YAIM
#
# You can check the puppet modules 'lcgdm' and 'dmlite' for any additional options available.
# !! Please replace the placeholders for usernames and passwords !!
#

#
# The standard variables are collected here:
#
$token_password = "TOKEN_PASSWORD"
$mysql_root_pass = "PASS"
$db_user = "dpmmgr"
$db_pass = "MYSQLPASS"
$localdomain = "cern.ch"
$volist = ["dteam", "atlas", "lhcb"]
$disk_nodes = "${::fqdn} dpmdisk01.cern.ch dpmdisk02.cern.ch"
$xrootd_sharedkey = "A32TO64CHARACTERKEY"
$debug = false

#
# Set inter-module dependencies
#
Class[Mysql::Server] -> Class[Lcgdm::Ns::Service]
#Class[Lcgdm::Dpm::Service] -> Lcgdm::Dpm::Pool <| |>
Class[Lcgdm::Dpm::Service] -> Class[Dmlite::Plugins::Adapter::Install]
Class[Dmlite::Plugins::Adapter::Install] ~> Class[Dmlite::Srm]
Class[Dmlite::Plugins::Adapter::Install] ~> Class[Dmlite::Gridftp]
Class[Dmlite::Plugins::Adapter::Install] ~> Class[Dmlite::Dav]
Class[Dmlite::Plugins::Mysql::Install] ~> Class[Dmlite::Srm]
Class[Dmlite::Plugins::Mysql::Install] ~> Class[Dmlite::Gridftp]
Class[Dmlite::Plugins::Mysql::Install] ~> Class[Dmlite::Dav]

#
# The firewall configuration
#
firewall{"050 allow http and https":
  proto  => "tcp",
  dport  => [80, 443],
  action => "accept"
}
firewall{"050 allow rfio":
  state  => "NEW",
  proto  => "tcp",
  dport  => "5001",
  action => "accept"
}
firewall{"050 allow rfio range":
  state  => "NEW",
  proto  => "tcp",
  dport  => "20000-25000",
  action => "accept"
}
firewall{"050 allow gridftp control":
  state  => "NEW",
  proto  => "tcp",
  dport  => "2811",
  action => "accept"
}
firewall{"050 allow gridftp range":
  state  => "NEW",
  proto  => "tcp",
  dport  => "20000-25000",
  action => "accept"
}
firewall{"050 allow srmv2.2":
  state  => "NEW",
  proto  => "tcp",
  dport  => "8446",
  action => "accept"
}
firewall{"050 allow xrootd":
  state  => "NEW",
  proto  => "tcp",
  dport  => "1095",
  action => "accept"
}
firewall{"050 allow cmsd":
  state  => "NEW",
  proto  => "tcp",
  dport  => "1094",
  action => "accept"
}

firewall{"050 allow DPNS":
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

#
# MySQL server setup - disable if it is not local
#
class{"mysql::server":
  service_enabled => true,
  root_password   => "${mysql_root_pass}"
}

#
# DPM and DPNS daemon configuration.
#
class{"lcgdm":
  dbflavor => "mysql",
  dbuser   => "${db_user}",
  dbpass   => "${db_pass}",
  dbhost   => "localhost",
  domain   => "${localdomain}",
  volist   => $volist,
  uid      => 151,
}

#
# RFIO configuration.
#
class{"lcgdm::rfio":
  dpmhost => "${::fqdn}",
}

#
# You can define your pools here (example is commented).
#
#lcgdm::dpm::pool{"mypool":
#  def_filesize => "100M"
#}
#
#
# You can define your filesystems here (example is commented).
#
#lcgdm::dpm::filesystem {"${fqdn}-myfsname":
#  pool   => "mypool",
#  server => "${fqdn}",
#  fs     => "/fslocation"
#}

#
# Entries in the shift.conf file, you can add in 'host' below the list of
# machines that the DPM should trust (if any).
#
lcgdm::shift::trust_value{
  "DPM TRUST":
    component => "DPM",
    host      => "${disk_nodes}";
  "DPNS TRUST":
    component => "DPNS",
    host      => "${disk_nodes}";
  "RFIO TRUST":
    component => "RFIOD",
    host      => "${disk_nodes}",
    all       => true
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
  localmap     => {"nobody" => "nogroup"}
}

#
# dmlite configuration.
#
class{"dmlite::head":
  token_password => "${token_password}",
  mysql_username => "${db_user}",
  mysql_password => "${db_pass}",
}

#
# Frontends based on dmlite.
#
class{"dmlite::dav":}
class{"dmlite::srm":}
class{"dmlite::gridftp":
  dpmhost => "${::fqdn}"
}


# The XrootD configuration is a bit more complicated and
# the full config (incl. federations) will be explained here:
# https://svnweb.cern.ch/trac/lcgdm/wiki/Dpm/Xroot/PuppetSetup

#
# The simplest xrootd configuration.
#
class{"xrootd::config":
  xrootd_user  => 'dpmmgr',
  xrootd_group => 'dpmmgr'
}
class{"dmlite::xrootd":
  nodetype              => [ 'head' ],
  domain                => "${localdomain}",
  dpm_xrootd_debug      => $debug,
  dpm_xrootd_sharedkey  => "${xrootd_sharedkey}"
}

#
# dmlite shell configuration.
#
#class{"dmlite::shell":}
