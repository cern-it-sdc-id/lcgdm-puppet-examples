class{"dpm::head_disknode":
   configure_repos      => false,
   configure_default_pool => true,
   configure_default_filesystem => true,
   disk_nodes => ['localhost'],
   localdomain => "cern.ch",
   db_pass => "MYSQLPASS",
   mysql_root_pass => "mysqlroot",
   token_password => "A32TO1024CHARAfdfCTERKEYTESTTESTTESTTESTTESTETEERETTETETE",
   xrootd_sharedkey => "A32TO64CHARACTERKEYTESTTESTTESTTEST",
   site_name => "CERN_DPM_TEST",
   new_installation => true,
   volist  => ['dteam', 'lhcb'],
   mountpoints => ['/srv/dpm','/srv/dpm/01', '/srv/dpm/02'],
   pools => ['mypool:100M'],
   filesystems => ["mypool:${fqdn}:/srv/dpm/01", "mypool:${fqdn}:/srv/dpm/02"],
   configure_dome => true,
   configure_domeadapter => true,
   configure_legacy => true,
   memcached_enabled => false,
   host_dn => "/DC=ch/DC=cern/OU=computers/CN=${fqdn}"
}
