#
# This is an example configuration for a DPM gateway to HDFS plugin
#
# You can check the puppet modules 'lcgdm' and 'dmlite' for any additional options available.
# !! Please replace the placeholders for usernames and passwords !!
#

#
# The standard variables are collected here:
#
headnode_fqdn = "dpmhdfs-gridftp.cern.ch"
$token_password = "change-this"
$mysql_root_pass = "PASS"
$db_user = "dpmmgr"
$db_pass = "MYSQLPASS"
$localdomain = "cern.ch"
$volist = ["dteam", "atlas"]
$disk_nodes = "${::fqdn}"
$xrootd_sharedkey = "A32TO64CHARACTERKEYTESTTESTTESTTEST"
$debug = false

#
# Set inter-module dependencies
#
Class[Dmlite::Plugins::Hdfs::Install] -> Class[Dmlite::Gridftp]
Class[Dmlite::Plugins::Hdfs::Install] -> Class[Dmlite::Dav::Config]
Class[Dmlite::Plugins::Hdfs::Install] -> Class[Xrootd::Config]
Class[Dmlite::Plugins::Mysql::Install] -> Class[Dmlite::Gridftp]
Class[Dmlite::Plugins::Mysql::Install] -> Class[Dmlite::Dav::Config]
Class[Dmlite::Plugins::Mysql::Install] ->  Class[Xrootd::Config]



Class[Dmlite::Plugins::Hdfs::Config]  -> Class[Dmlite::Dav::Config]
Class[Dmlite::Plugins::Hdfs::Config] -> Class[Dmlite::Gridftp]
Class[Dmlite::Plugins::Hdfs::Config] -> Class[Dmlite::Xrootd]

Class[fetchcrl::service] -> Class[Xrootd::Config]
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


# lcgdm configuration.
#
class{"lcgdm::base::config":}
class{"lcgdm::base::install":}

class{"lcgdm::ns::client":
  flavor  => "dpns",
  dpmhost => "${headnode_fqdn}"
}

#
# VOMS configuration (same VOs as above).
#
class{"voms::atlas":}
class{"voms::dteam":}

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
  localmap     => {"nobody" => "nogroup"},
}

#
# dmlite configuration.
#


class{"dmlite::disk_hdfs":
  token_password => "${token_password}",
  mysql_username => "${db_user}",
  mysql_password => "${db_pass}",
  hdfs_namenode  => 'dpmhdfs02.cern.ch',
  hdfs_port      => 9000,
  hdfs_user      => 'hdfs',
  enable_io      => true,
}

#
# Frontends based on dmlite.
#
class{"dmlite::dav::install":}
class{"dmlite::dav::config":
  enable_hdfs => true
}
class{"dmlite::dav::service":}

class{"dmlite::gridftp":
  dpmhost => "${::fqdn}",
  enable_hdfs => true,
  data_node => 1
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
  nodetype              => [ 'disk' ],
  domain                => "${localdomain}",
  dpm_xrootd_debug      => $debug,
  dpm_xrootd_sharedkey  => "${xrootd_sharedkey}",
  enable_hdfs           => true,
}


#limit conf

$limits_config = {
    "*" => {
      nofile => { soft => 65000, hard => 65000 },
      nproc  => { soft => 65000, hard => 65000 },
    }
  }
  class{'limits':
    config    => $limits_config,
    use_hiera => false
  }


