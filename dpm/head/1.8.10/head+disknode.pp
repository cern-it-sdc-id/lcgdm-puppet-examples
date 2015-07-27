#
# This is an example configuration for a DPM Head + Disk Node  
#
# You can check the puppet modules 'lcgdm' and 'dmlite' for any additional options available.
# !! Please replace the placeholders for usernames and passwords !!
#

#
#
# The standard variables are collected here:
#
# the dmlite token password, it has the same value as the YAIM var DMLITE_TOKEN_PASSWORD
$token_password = "TOKEN_PASSWORD"
#The Mysql root pass ( if Mysql is installed locally), it has the same value as the  YAIM var MYSQL_PASSWORD
$mysql_root_pass = "PASS"
#the DPM DB user, it has the same value as the YAIM var DPM_DB_USER
$db_user = "dpmmgr"
#the DPM DB user password, it has the same value as the YAIM var DPM_DB_PASSWORD
$db_pass = "MYSQLPASS"
#the DPM DB host, it has the same value as the YAIM var DPM_DB_HOST
$db_host = "localhost"
# the DPM host domain, it has the same value as the YAIM var MY_DOMAIN
$localdomain = "cern.ch"
# the list of VO tu support, it has the same value as the YAIM var VOS
$volist = ["dteam", "atlas"]
# the list of disknodes to configure
$disk_nodes = ["${::fqdn}"]
# the xrootd shared key, it  has the same value as the YAIM var DPM_XROOTD_SHAREDKEY
$xrootd_sharedkey = "A32TO64CHARACTERKEYTESTTESTTESTTEST"
#enable debug logs
$debug = false
#enable installation and configuration of the DB locally
$local_db = true
# the dpmmgr UID, it  has the same value as the YAIM var DPMMGR_UID
$dpmmgr_uid = 151
# the dpmmgr GID, it  has the same value as the YAIM var DPMMGR_GID
$dpmmgr_gid = 151



#
# Set inter-module dependencies
#
Class[Lcgdm::Dpm::Service] -> Class[Dmlite::Plugins::Adapter::Install]
Class[Lcgdm::Ns::Config] -> Class[Dmlite::Srm::Service]
Class[Dmlite::Head] -> Class[Dmlite::Plugins::Adapter::Install]
Class[Dmlite::Plugins::Adapter::Install] ~> Class[Dmlite::Srm]
Class[Dmlite::Plugins::Adapter::Install] ~> Class[Dmlite::Gridftp]
Class[Dmlite::Plugins::Adapter::Install] -> Class[Dmlite::Dav]
Dmlite::Plugins::Adapter::Create_config <| |> -> Class[Dmlite::Dav::Install]
Class[Dmlite::Plugins::Mysql::Install] ~> Class[Dmlite::Srm]
Class[Dmlite::Plugins::Mysql::Install] ~> Class[Dmlite::Gridftp]
Class[Dmlite::Plugins::Mysql::Install] -> Class[Dmlite::Dav]
Class[Bdii::Install] -> Class[Lcgdm::Bdii::Dpm]
Class[Lcgdm::Bdii::Dpm] -> Class[Bdii::Service]
Class[fetchcrl::service] -> Class[Xrootd::Config]
Class[Mysql::Server] -> Class[Lcgdm::Ns::Service]
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
firewall{"050 allow DPM":
  state  => "NEW",
  proto  => "tcp",
  dport  => "5015",
  action => "accept"
}
firewall{"050 allow MySQL":
  state  => "NEW",
  proto  => "tcp",
  dport  => "3306",
  action => "accept"
}

#
# MySQL server setup - disable if it is not local
#
if ($local_db) {

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

  #configure grants
  mysql_user { "${db_user}@${disk_nodes}":
    ensure        => present,
    password_hash => "${db_pass}",
    provider      => 'mysql',
  }

  mysql_grant { "${db_user}@${disk_nodes}/cns_db.*":
        ensure     => 'present',
        options    => ['GRANT'],
        privileges => ['ALL'],
        table      => 'cns_db.*',
        user       => "${db_user}@${disk_nodes}",
        provider   => 'mysql',
        require    => [ Mysql_database['cns_db'], Mysql_user["${db_user}@${disk_nodes}"] ],
  }

  firewall{"050 allow mysql":
    state  => "NEW",
    proto  => "tcp",
    dport  => "3316",
    action => "accept"
  }
}
else {
  class{"mysql::server":
    service_enabled => false,
  }
}

#
# DPM and DPNS daemon configuration.
#
class{"lcgdm":
  dbflavor => "mysql",
  dbuser   => "${db_user}",
  dbpass   => "${db_pass}",
  dbhost   => "${db_host}",
  domain   => "${localdomain}",
  volist   => $volist,
  uid      => $dpmmgr_uid,
  gid      => $dpmmgr_gid,
}

#
# RFIO configuration.
#
class{"lcgdm::rfio":
  dpmhost => "${::fqdn}",
}



#
# You can define your pools here 
#
#the "mypool" value has the same value as the YAIM  var DPMPOOL
#the value of def_filesize has the same value of the YAIM var DPMFSIZE
#
#Class[Lcgdm::Dpm::Service] -> Lcgdm::Dpm::Pool <| |>
#lcgdm::dpm::pool{"mypool":
#  def_filesize => "100M"
#}
#
#
# You can define your filesystems here.
#
# the configuration is similar to what is defined in the YAIM var DPM_FILESYSTEMS
#
#Class[Lcgdm::Base::Config] ->
#file {
#   "/srv/dpm":
#   ensure => directory,
#   owner => "dpmmgr",
#   group => "dpmmgr",   
#   mode =>  0775;
#   "/srv/dpm/01":
#   ensure => directory,
#   owner => "dpmmgr",
#   group => "dpmmgr",
#   seltype => "httpd_sys_content_t",
#   mode => 0775;
#}
#->
#lcgdm::dpm::filesystem {"${fqdn}-myfsname":
#  pool   => "mypool",
#  server => "${fqdn}",
#  fs     => "/srv/dpm"
#}

#
# Entries in the shift.conf file, you can add in 'host' below the list of
# machines that the DPM should trust (if any).
#
lcgdm::shift::trust_value{
  "DPM TRUST":
    component => "DPM",
    host      => join($disk_nodes,' ');
  "DPNS TRUST":
    component => "DPNS",
    host      => join($disk_nodes,' ');
  "RFIO TRUST":
    component => "RFIOD",
    host      => join($disk_nodes,' '),
    all       => true
}
lcgdm::shift::protocol{"PROTOCOLS":
  component => "DPM",
  proto     => "rfio gsiftp http https xroot"
}

#
# VOMS configuration (same VOs as above).
#
# It replaces the YAIM conf
# VO_<vo_name>_VOMSES="'vo_name voms_server_hostname port voms_server_host_cert_dn vo_name' ['...']"
# VO_<vo_name>_VOMS_CA_DN="'voms_server_ca_dn' ['...']"

#
class{"voms::atlas":}
class{"voms::dteam":}

#
# Gridmapfile configuration.
#
# it corresponds to the YAIM conf
# VO_<vo_name>_VOMS_SERVERS="'vomss://<host-name>:8443/voms/<vo-name>?/<vo-name>' ['...']"
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

exec{"/usr/sbin/edg-mkgridmap --conf=/etc/lcgdm-mkgridmap.conf --safe --output=/etc/lcgdm-mapfile":
        require => Lcgdm::Mkgridmap::File["lcgdm-mkgridmap"]
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
# the xrootd_user and xrootd_group vars are configured as in YAIM with the value of DPMMGR_USER
#
class{"xrootd::config":
  xrootd_user  => 'dpmmgr',
  xrootd_group => 'dpmmgr'
}
class{"dmlite::xrootd":
  nodetype              => [ 'head','disk' ],
  domain                => "${localdomain}",
  dpm_xrootd_debug      => $debug,
  dpm_xrootd_sharedkey  => "${xrootd_sharedkey}"
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
Class[Dmlite::Plugins::Memcache::Install] ~> Class[Dmlite::Srm]

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


