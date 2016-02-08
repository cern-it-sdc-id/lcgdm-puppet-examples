#
# This is an example configuration for a DPM Disk Node, reference to deprecated YAIM variable are given in case of a DPM previously configured via YAIM
#
# You can check the puppet module 'lcgdm' and 'dmlite' for any additional options available.
# !! Please replace the placeholders for usernames, passwords an hostnames!!
#

#
# The standard variables are collected here:
#
# the FQDN of the Headnode
$headnode_fqdn = "HEADNODE"
#the DPM DB user, it has the same value as the YAIM var DPM_DB_USER
$db_user = "dpmmgr"
#the DPM DB user password, it has the same value as the YAIM var DPM_DB_PASSWORD
$db_pass = "MYSQLPASS"
#the DPM DB host, it has the same value as the YAIM var DPM_DB_HOST
$db_host = "HEADNODE"
# the dmlite token password, it has the same value as the YAIM var DMLITE_TOKEN_PASSWORD
$token_password = "TOKEN_PASSWORD"
# the DPM host domain, it has the same value as the YAIM var MY_DOMAIN
$localdomain = "cern.ch"
# the list of VO tu support, it has the same value as the YAIM var VOS
$volist = ["dteam", "atlas"]
# the list of disknodes to configure
$disk_nodes = "${::fqdn} DISKNODE1"
# the xrootd shared key, it  has the same value as the YAIM var DPM_XROOTD_SHAREDKEY
$xrootd_sharedkey = "A32TO64CHARACTERKEYTESTTESTTESTTEST"
#enable debug logs
$debug = false
# the dpmmgr UID, it  has the same value as the YAIM var DPMMGR_UID
$dpmmgr_uid = 151
# the dpmmgr GID, it  has the same value as the YAIM var DPMMGR_GID
$dpmmgr_gid = 151

#
# Set inter-module dependencies
#
Class[lcgdm::base::install] -> Class[lcgdm::rfio::install]
Class[dmlite::plugins::adapter::install] ~> Class[dmlite::dav::service]
Class[dmlite::plugins::adapter::install] ~> Class[dmlite::gridftp]
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


#
# lcgdm mountpoints configuration example
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


#
# lcgdm configuration, we explicitly set uid and gid for the dpmmgr user 
#
class{"lcgdm::base":
  uid      => $dpmmgr_uid,
  gid      => $dpmmgr_gid,
}

class{"lcgdm::ns::client":
  flavor  => "dpns",
  dpmhost => "${headnode_fqdn}"
}

#
# RFIO configuration.
#
class{"lcgdm::rfio":
  dpmhost => "${headnode_fqdn}",
}

#
# Entries in the shift.conf file, you can add in 'host' below the list of
# machines that the DPM should trust (if any).
#
lcgdm::shift::trust_value{
  "DPM TRUST":
    component => "DPM",
    host      => "${headnode_fqdn} ${disk_nodes}";
  "DPNS TRUST":
    component => "DPNS",
    host      => "${headnode_fqdn} ${disk_nodes}";
  "RFIO TRUST":
    component => "RFIOD",
    host      => "${headnode_fqdn} ${disk_nodes}",
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
  localmap     => {"nobody" => "nogroup"}
}

#
# dmlite plugin configuration.
class{"dmlite::disk":
  token_password => "${token_password}",
  dpmhost        => "${headnode_fqdn}",
  nshost         => "${headnode_fqdn}",
  mysql_username => "${db_user}",
  mysql_password => "${db_pass}",
  mysql_host     => "${db_host}",
  enable_space_reporting => true,
}

#
# dmlite frontend configuration.
#
class{"dmlite::dav":}
class{"dmlite::gridftp":
  dpmhost => "${headnode_fqdn}"
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
  nodetype              => [ 'disk' ],
  domain                => "${localdomain}",
  dpm_xrootd_debug      => $debug,
  dpm_xrootd_sharedkey  => "${xrootd_sharedkey}"
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


