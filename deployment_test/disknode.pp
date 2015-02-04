#
# This is an example configuration for a DPM Disk Node.
#
# You can check the puppet module 'lcgdm' and 'dmlite' for any additional options available.
# !! Please replace the placeholders for usernames and passwords !!
#

#
# The standard variables are collected here:
#
$headnode_fqdn = "HEADNODE"
$token_password = "TOKEN_PASSWORD"
$mysql_root_pass = "PASS"
$db_user = "dpmmgr"
$db_pass = "MYSQLPASS"
$localdomain = "cern.ch"
$volist = ["dteam", "atlas", "lhcb"]
$disk_nodes = "${::fqdn} dpmdisk01.cern.ch dpmdisk02.cern.ch"
$xrootd_sharedkey = "A32TO64CHARACTERKEYTESTTESTTESTTEST"
$debug = false



Class[Lcgdm::Base::Install] -> Class[Lcgdm::Rfio::Install]
Class[Dmlite::Plugins::Adapter::Install] ~> Class[Dmlite::Dav::Service]
Class[Dmlite::Plugins::Adapter::Install] ~> Class[Dmlite::Gridftp]

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

#
# lcgdm mountpoints configuration
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

#
# lcgdm configuration.
#
class{"lcgdm::base::config":}
class{"lcgdm::base::install":}

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
# dmlite plugin configuration.
class{"dmlite::disk":
  token_password => "${token_password}",
  dpmhost        => "${headnode_fqdn}",
  nshost         => "${headnode_fqdn}",
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
class{"xrootd::config":
  xrootd_user  => 'dpmmgr',
  xrootd_group => 'dpmmgr'
}
class{"dmlite::xrootd":
  nodetype              => [ 'disk' ],
  domain                => "${localdomain}",
  dpm_xrootd_debug      => $debug,
  dpm_xrootd_sharedkey  => "${xrootd_sharedkey}",
}

#
# dmlite shell configuration.
#
#class{"dmlite::shell":}
