class{"dpm::headnode":
   disk_nodes => [ "dpmdisk01.cern.ch", "dpmdisk02.cern.ch" ],
   localdomain => "cern.ch",
   db_pass => "MYSQLPASS",
   mysql_root_pass => "PASS",
   token_password => "TOKEN_PASSWORD",
   xrootd_sharedkey => "A32TO64CHARACTERKEYTESTTESTTESTTEST",
   site_name => "CERN_DPM_TEST",
   volist =>[dteam],
}
