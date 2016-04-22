#
# This is an example configuration for a DPM Head + Disk Node  with HDFS plugin
#
# You can check the puppet modules 'lcgdm' and 'dmlite' for any additional options available.
# !! Please replace the placeholders for usernames and passwords !!
#

#
# The standard variables are collected here:
#
$token_password = "change-this"
$mysql_root_pass = "PASS"
$db_user = "dpmmgr"
$db_pass = "MYSQLPASS"
$localdomain = "cern.ch"
$volist = ["dteam", "atlas"]
$disk_nodes = "${::fqdn}"
$xrootd_sharedkey = "A32TO64CHARACTERKEYTESTTESTTESTTEST"
$debug = false
$local_db = true

#
# Set inter-module dependencies
#
Class[dmlite::plugins::hdfs::install] -> Class[dmlite::gridftp]
Class[dmlite::plugins::hdfs::install] -> Class[dmlite::dav::config]
Class[dmlite::plugins::hdfs::install] -> Class[xrootd::config]
Class[dmlite::plugins::mysql::install] -> Class[dmlite::gridftp]
Class[dmlite::plugins::mysql::install] -> Class[dmlite::dav::config]
Class[dmlite::plugins::mysql::install] ->  Class[xrootd::config]

Class[dmlite::plugins::hdfs::config]  -> Class[dmlite::dav::config]
Class[dmlite::plugins::hdfs::config] -> Class[dmlite::gridftp]
Class[dmlite::plugins::hdfs::config] -> Class[dmlite::xrootd]

Class[bdii::install] -> Class[lcgdm::bdii::dpm]
Class[lcgdm::bdii::dpm] -> Class[bdii::service]
Class[fetchcrl::service] -> Class[xrootd::config]
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
if ($local_db) {
  Class[mysql::server] -> Class[lcgdm::ns::service]

  #adding perf tunings
  $override_options = {
  'mysqld' => {
    'max_connections'    => '1000',
    'query_cache_size'   => '256M',
    'query_cache_limit'  => '1MB',
    'innodb_flush_method' => 'O_DIRECT',
    'innodb_buffer_pool_size' => '1000000000',
    'bind-address' => '0.0.0.0',
  }
 }
  
  class{"mysql::server":
    service_enabled => true,
    root_password   => "${mysql_root_pass}",
    override_options  => $override_options,
    #this is set to false in the case of an existing DPM DB, for new installations it has to be set to true.
    create_root_user => false,
  }
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


class{"dmlite::head_hdfs":
  token_password => "${token_password}",
  mysql_username => "${db_user}",
  mysql_password => "${db_pass}",
  mysql_host     => "${db_host}",
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
  enable_hdfs => true
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
  nodetype              => [ 'head','disk' ],
  domain                => "${localdomain}",
  dpm_xrootd_debug      => $debug,
  dpm_xrootd_sharedkey  => "${xrootd_sharedkey}",
  enable_hdfs           => true,
}

# BDII
include('bdii')
   
# DPM GIP config
class{"lcgdm::bdii::dpm":
     sitename  => "CERN-DPM-TESTBED",
     vos => $volist
}

#memcache configuration
Class[dmlite::plugins::memcache::install] ~> Class[dmlite::dav::service]
Class[dmlite::plugins::memcache::install] ~> Class[dmlite::gridftp]
Class[dmlite::plugins::memcache::install] ~> Class[xrootd::service]

Class[lcgdm::base::config]
->
class{"memcached":
   max_memory => 2000,
   listen_ip  => "127.0.0.1",
   }
->
class{"dmlite::plugins::memcache":
   expiration_limit => 600,
   posix            => 'on',
   }

#
# dmlite shell configuration.
#
class{"dmlite::shell":}

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


