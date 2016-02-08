#
# This is an example configuration for a DPM Head + Disk Node  
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
$volist = ["dteam", "atlas"]
$disk_nodes = "${::fqdn}"
$xrootd_sharedkey = "A32TO64CHARACTERKEYTESTTESTTESTTEST"
$debug = false
$local_db = true

#
# Set inter-module dependencies
#
Class[lcgdm::dpm::service] -> Class[dmlite::plugins::adapter::install]
Class[lcgdm::ns::config] -> Class[dmlite::srm::service]
Class[dmlite::head] -> Class[dmlite::plugins::adapter::install]
Class[dmlite::plugins::adapter::install] ~> Class[dmlite::srm]
Class[dmlite::plugins::adapter::install] ~> Class[dmlite::gridftp]
Class[dmlite::plugins::adapter::install] -> Class[dmlite::dav]
Dmlite::Plugins::Adapter::Create_config <| |> -> Class[dmlite::dav::install]
Class[dmlite::plugins::mysql::install] ~> Class[dmlite::srm]
Class[dmlite::plugins::mysql::install] ~> Class[dmlite::gridftp]
Class[dmlite::plugins::mysql::install] -> Class[dmlite::dav]
Class[bdii::install] -> Class[lcgdm::bdii::dpm]
Class[lcgdm::bdii::dpm] -> Class[bdii::service]
Class[fetchcrl::service] -> Class[xrootd::config]
#memcache deps
Class[dmlite::plugins::memcache::install] ~> Class[dmlite::dav::service]    
Class[dmlite::plugins::memcache::install] ~> Class[dmlite::gridftp]
Class[dmlite::plugins::memcache::install] ~> Class[dmlite::srm]

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
  }
 }

  class{"mysql::server":
    service_enabled => true,
    root_password   => "${mysql_root_pass}",
    override_options  => $override_options
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
Class[lcgdm::dpm::service] -> Lcgdm::Dpm::Pool <| |>
lcgdm::dpm::pool{"mypool":
  def_filesize => "100M"
}
#
#
# You can define your filesystems here (example is commented).
#
Class[lcgdm::base::config] ->
file {
   "/srv/dpm":
   ensure => directory,
   owner => "dpmmgr",
   group => "dpmmgr",   
   mode =>  '0775';
   "/srv/dpm/01":
   ensure => directory,
   owner => "dpmmgr",
   group => "dpmmgr",
   seltype => "httpd_sys_content_t",
   mode => '0775';
}
->
lcgdm::dpm::filesystem {"${fqdn}-myfsname":
  pool   => "mypool",
  server => "${fqdn}",
  fs     => "/srv/dpm"
}

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
class{"voms::atlas":}
class{"voms::dteam":}

#
# Gridmapfile configuration.
#
$groupmap = {
  "vomss://voms.hellasgrid.gr:8443/voms/dteam?/dteam"                 => "dteam",
  "vomss://voms2.hellasgrid.gr:8443/voms/dteam?/dteam"                 => "dteam",
  "vomss://voms2.cern.ch:8443/voms/atlas?/atlas"                      => "atlas",
  "vomss://lcg-voms2.cern.ch:8443/voms/atlas?/atlas"                   => "atlas",
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
class{"xrootd::config":
  xrootd_user  => 'dpmmgr',
  xrootd_group => 'dpmmgr'
}
class{"dmlite::xrootd":
  nodetype              => [ 'head','disk' ],
  domain                => "${localdomain}",
  dpm_xrootd_debug      => $debug,
  dpm_xrootd_sharedkey  => "${xrootd_sharedkey}",
  log_style_param       => '-k fifo',
}

# BDII
include('bdii')
   
# DPM GIP config
class{"lcgdm::bdii::dpm":
     sitename  => "CERN-DPM-TESTBED",
     vos => [ "dteam", "atlas" ] 
}

#
# dmlite shell configuration.
#
class{"dmlite::shell":}

Class[lcgdm::base::config] ->
class{"memcached":
    max_memory => 512,
}
 ->
class{"dmlite::plugins::memcache":
      expiration_limit => 600,
      posix            => 'on',
      func_counter     => 'on',
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

