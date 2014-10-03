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
    "EMI-3-base":
      descr    => "EMI 3 Base Repository",
      baseurl  => "http://emisoft.web.cern.ch/emisoft/dist/EMI/3/sl6/\$basearch/base",
      gpgkey   => "http://emisoft.web.cern.ch/emisoft/dist/EMI/3/RPM-GPG-KEY-emi",
      gpgcheck => 0,
      priority => 45,
      protect  => 1,
      enabled  => 1;
    "EMI-3-updates":
      descr    => "EMI 3 Updates Repository",
      baseurl  => "http://emisoft.web.cern.ch/emisoft/dist/EMI/3/sl6/\$basearch/updates",
      gpgkey   => "http://emisoft.web.cern.ch/emisoft/dist/EMI/3/RPM-GPG-KEY-emi",
      gpgcheck => 0,
      priority => 45,
      protect  => 1,
      enabled  => 1;
    "EMI-3-third-party":
      descr     => "EMI 3 Third-Party Repository",
      baseurl  => "http://emisoft.web.cern.ch/emisoft/dist/EMI/3/sl6/\$basearch/third-party",
      protect  => 1,
      enabled  => 1,
      priority => 45,
      gpgcheck => 0;
    "wlcg":
      descr    => "WLCG Repository",
      baseurl  => "http://linuxsoft.cern.ch/wlcg/sl6/\$basearch",
      protect  => 1,
      enabled  => 1,
      priority => 20,
      gpgcheck => 0;
  }
