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
#memcache deps
Class[Dmlite::Plugins::Memcache::Install] ~> Class[Dmlite::Dav::Service]    
Class[Dmlite::Plugins::Memcache::Install] ~> Class[Dmlite::Gridftp]
Class[Dmlite::Plugins::Memcache::Install] ~> Class[Dmlite::Srm]

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
  Class[Mysql::Server] -> Class[Lcgdm::Ns::Service]
  class{"mysql::server":
    service_enabled => true,
    root_password   => "${mysql_root_pass}"
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
# RFIO configuration.
#
class{"lcgdm::rfio":
  dpmhost => "${::fqdn}",
}



#
# You can define your pools here (example is commented).
#
Class[Lcgdm::Dpm::Service] -> Lcgdm::Dpm::Pool <| |>
lcgdm::dpm::pool{"mypool":
  def_filesize => "100M"
}
#
#
# You can define your filesystems here (example is commented).
#
Class[Lcgdm::Base::Config] ->
file {
   "/srv/dpm":
   ensure => directory,
   owner => "dpmmgr",
   group => "dpmmgr",   
   mode =>  0775;
   "/srv/dpm/01":
   ensure => directory,
   owner => "dpmmgr",
   group => "dpmmgr",
   seltype => "httpd_sys_content_t",
   mode => 0775;
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
  vomsxrd_package       => "vomsxrd4",
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

Class[Lcgdm::Base::Config] ->
class{"memcached":
    max_memory => 512,
}
 ->
class{"dmlite::plugins::memcache":
      expiration_limit => 600,
      posix            => 'on',
      func_counter     => 'on',
}
