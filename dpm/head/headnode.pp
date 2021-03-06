#
# This is an example configuration for a DPM Head Node.
#
# You can check the puppet modules 'lcgdm' and 'dmlite' for any additional options available.
# !! Please replace the placeholders for usernames and passwords !!
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
$disk_nodes = "dpmdisk01.cern.ch dpmdisk02.cern.ch"
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
# the site name to be published to the BII
$site_name = "YOUR SITE NAME"

#
# Set inter-module dependencies
#
Class[lcgdm::dpm::service] -> Class[dmlite::plugins::adapter::install]
Class[dmlite::head] -> Class[dmlite::plugins::adapter::install]
Class[dmlite::plugins::adapter::install] ~> Class[dmlite::srm]
Class[dmlite::plugins::adapter::install] ~> Class[dmlite::gridftp]
Class[dmlite::plugins::adapter::install] ~> Class[dmlite::dav]
Dmlite::Plugins::Adapter::Create_config <| |> -> Class[dmlite::dav::install]
Class[dmlite::plugins::mysql::install] ~> Class[dmlite::srm]
Class[dmlite::plugins::mysql::install] ~> Class[dmlite::gridftp]
Class[dmlite::plugins::mysql::install] ~> Class[dmlite::dav]
Class[fetchcrl::service]-> Class[xrootd::config]
Class[bdii::install] -> Class[lcgdm::bdii::dpm]
Class[lcgdm::bdii::dpm] -> Class[bdii::service]

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

  #perforimance tunings options
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
    #this is set to false in the case of an existing DPM DB or if the root user has been already created manually, for new installations it has to be set to true.
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
# You can define your pools here (example is commented).
#
#the "mypool" value has the same value as the YAIM  var DPMPOOL
#the value of def_filesize has the same value of the YAIM var DPMFSIZE
#
#Class[lcgdm::dpm::service] -> Lcgdm::Dpm::Pool <| |>
#lcgdm::dpm::pool{"mypool":
#  def_filesize => "100M"
#}
#
#
# You can define your filesystems here (example is commented).
#
# the configuration is similar to what is defined in the YAIM var DPM_FILESYSTEMS
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
    host      => "${disk_nodes} ${::fqdn}";
  "DPNS TRUST":
    component => "DPNS",
    host      => "${disk_nodes} ${::fqdn}";
  "RFIO TRUST":
    component => "RFIOD",
    host      => "${disk_nodes} ${::fqdn}",
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
# it correspond to the YAIM conf
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
  localmap     => {"nobody" => "nogroup"}
}

#
# dmlite configuration.
#
class{"dmlite::head":
  token_password => "${token_password}",
  mysql_username => "${db_user}",
  mysql_password => "${db_pass}",
  mysql_host     => "${db_host}",
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
  nodetype              => [ 'head' ],
  domain                => "${localdomain}",
  dpm_xrootd_debug      => $debug,
  dpm_xrootd_sharedkey  => "${xrootd_sharedkey}"
}
# BDII
include('bdii')
   
# DPM GIP config
class{"lcgdm::bdii::dpm":
     sitename  => "${site_name}",
     vos => $volist
}

#memcache configuration
Class[dmlite::plugins::memcache::install] ~> Class[dmlite::dav::service]
Class[dmlite::plugins::memcache::install] ~> Class[dmlite::gridftp]
Class[dmlite::plugins::memcache::install] ~> Class[dmlite::srm]

Class[lcgdm::base::config]
->
class{"memcached":
   # the memory in MB assigned to memcached
   max_memory => 2000,
   # access from localhost only
   listen_ip  => "127.0.0.1",
   }
->
class{"dmlite::plugins::memcache":
   # cache entry expiration limit, in seconds
   expiration_limit => 600,
   # use posix style when accessing folder content
   posix            => 'on',
   }

#
# dmlite shell configuration.
#
class{"dmlite::shell":}
