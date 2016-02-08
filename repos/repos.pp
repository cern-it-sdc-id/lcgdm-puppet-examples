  yumrepo {
    "epel":
      descr    => "Extra Packages for Enterprise Linux add-ons",
      baseurl  => "http://linuxsoft.cern.ch/epel/${lsbmajdistrelease}/\$basearch",
      gpgcheck => 0,
      enabled  => 1,
      protect  => 1;
     "EGI-trustanchors":
      descr    => EGI-trustanchors,
      baseurl  => "http://repository.egi.eu/sw/production/cas/1/current/",
      #gpgkey  => "http://repository.egi.eu/sw/production/cas/1/GPG-KEY-EUGridPMA-RPM-3",
      gpgcheck => 0,
      enabled  => 1;
    "wlcg":
      descr    => "WLCG Repository",
      baseurl  => "http://linuxsoft.cern.ch/wlcg/sl6/\$basearch",
      protect  => 1,
      enabled  => 1,
      priority => 20,
      gpgcheck => 0;
  }
