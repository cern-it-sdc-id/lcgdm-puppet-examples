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
$disk_nodes = 'dpmhdfs-gateway.cern.ch dpmhdfs01.cern.ch'
$xrootd_sharedkey = "A32TO64CHARACTERKEYTESTTESTTESTTEST"
$debug = false
$local_db = true

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

Class[Bdii::Install] -> Class[Lcgdm::Bdii::Dpm]
Class[Lcgdm::Bdii::Dpm] -> Class[Bdii::Service]
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

firewall{"050 allow mysql":
  state  => "NEW",
  proto  => "tcp",
  dport  => "3306",
  action => "accept"
}
#
# MySQL server setup - disable if it is not local
#
if ($local_db) {
  Class[Mysql::Server] -> Class[Lcgdm::Ns::Service]

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
    override_options  => $override_options
  }
 
   mysql_user { "${db_user}@dpmhdfs01.cern.ch":
    ensure        => present,
    password_hash => mysql_password($db_pass),
    provider      => 'mysql',
  }

   mysql_grant { "${db_user}@dpmhdfs01.cern.ch/dpm_db.*":
        ensure     => 'present',
        options    => ['GRANT'],
        privileges => ['ALL'],
        table      => 'dpm_db.*',
        user       => "${db_user}@dpmhdfs01.cern.ch",
  }

  mysql_grant { "${db_user}@dpmhdfs01.cern.ch/cns_db.*":
        ensure     => 'present',
        options    => ['GRANT'],
        privileges => ['ALL'],
        table      => 'cns_db.*',
        user       => "${db_user}@dpmhdfs01.cern.ch",
  }
  mysql_user { "${db_user}@dpmhdfs-gateway.cern.ch":
    ensure        => present,
    password_hash => mysql_password($db_pass),
    provider      => 'mysql',
  }

  mysql_grant { "${db_user}@dpmhdfs-gateway.cern.ch/dpm_db.*":
        ensure     => 'present',
        options    => ['GRANT'],
        privileges => ['ALL'],
        table      => 'dpm_db.*',
        user       => "${db_user}@dpmhdfs-gateway.cern.ch",
  }

  mysql_grant { "${db_user}@dpmhdfs-gateway.cern.ch/cns_db.*":
        ensure     => 'present',
        options    => ['GRANT'],
        privileges => ['ALL'],
        table      => 'cns_db.*',
        user       => "${db_user}@dpmhdfs-gateway.cern.ch",
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
  hdfs_namenode  => 'dpmhdfs02.cern.ch',
  hdfs_port      => 9000,
  hdfs_user      => 'hdfs',
  hdfs_gateway   =>  join($disk_nodes, ','),
}

#
# Frontends based on dmlite.
#
class{"dmlite::dav::install":}
class{"dmlite::dav::config":
  enable_hdfs => true
}
class{"dmlite::dav::service":}

$remotes = suffix($disk_nodes, ':2811')
$remote_nodes = join($remotes, ',')

class{"dmlite::gridftp":
  dpmhost => "${::fqdn}",
  remote_nodes => $remote_nodes,
  enable_hdfs => true,
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
Class[Dmlite::Plugins::Memcache::Install] ~> Class[Dmlite::Dav::Service]
Class[Dmlite::Plugins::Memcache::Install] ~> Class[Dmlite::Gridftp]
Class[Dmlite::Plugins::Memcache::Install] ~> Class[Xrootd::Service]

Class[Lcgdm::Base::Config]
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
# dmlite shell configuration to add pool
#

package {'dmlite-shell':
        ensure => present;
}

exec { "configurepool":
  path        => '/bin:/sbin:/usr/bin:/usr/sbin',
  environment => ['LD_LIBRARY_PATH=/usr/lib/jvm/java/jre/lib/amd64/server/'],
  command     => "dmlite-shell -e 'pooladd  hdfs_pool hdfs';dmlite-shell -e 'poolmodify hdfs_pool hostname dpmhdfs02.cern.ch';dmlite-shell -e 'poolmodify hdfs_pool port 9000'; dmlite-shell -e 'poolmodify hdfs_pool username hdfs'; dmlite-shell -e 'poolmodify hdfs_pool mode rw'",
  #unless      => "dmlite-shell -e 'poolinfo rw'",
  require     => Package['dmlite-shell'],
}

