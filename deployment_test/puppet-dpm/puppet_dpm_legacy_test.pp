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
   mountpoints => ['/srv/dpm','/srv/dpm/01'],
   pools => ['mypool:100M'],
   filesystems => ["mypool:${fqdn}:/srv/dpm/01"],
   configure_dome => false,
   configure_domeadapter => false,
   configure_legacy => true
}
