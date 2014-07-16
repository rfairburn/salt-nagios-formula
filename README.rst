nagios
=======

Salt formula to set up and manage nagios and nrpe.

.. note::

    See the full `Salt Formulas installation and usage instructions
    <http://docs.saltstack.com/topics/conventions/formulas.html>`_.

Available states
================

``nagios``
----------
    Set up the nagios server and nrpe

``nagios.server``
----------
    Set up nagios server

``nagios.nrpe``
----------
    Setup nrpe and auto populate server to be monitored with default checks


Example Pillar:

.. code:: yaml

    nagios:
      config:
        high_service_flap_threshold: 22.0
        cfg_dirs:
          - /etc/nagios/conf.d
          - /etc/nagios/servers
      resource_cfg:
        USER1: /usr/lib64/nagios/plugins
        USER2: /dev/null
      passwd_cfg:
        nagiosadmin: RbdO4ou4PNyMg
      include_default_files: True
      included_config_files: []
      additional_configs:
        /tmp/test.cfg:
          service:
            foo_service:
              foo_setting: foo_value
              foo_setting2: another_foo_value
          host:
            foo_host:
              foo_setting: foo_value
              foo_setting2: another_foo_value 
    
    nrpe:
      config:
        commands:
          check_total_procs: '/usr/lib64/nagios/plugins/check_procs -w 150 -c 200'
          check_load: '/usr/lib64/nagios/plugins/check_load -w 15,10,5 -c 30,25,20'
          check_users: '/usr/lib64/nagios/plugins/check_users -w 5 -c 10'
          check_hda1: '/usr/lib64/nagios/plugins/check_disk -w 20% -c 10% -p /dev/hda1'
          check_zombie_procs: '/usr/lib64/nagios/plugins/check_procs -w 5 -c 10 -s Z'
          check_xvda1: '/usr/lib64/nagios/plugins/check_disk -w 20% -c 10% -p /dev/xvda1'
      additional_configs:
        /etc/nrpe.d/test.cfg:
          options:
            dont_blame_nrpe: 1
          commands:
            check_disks: '/usr/lib64/nagios/plugins/check_disk -w $ARG1$ -c $ARG2$ -A -X tmpfs -X devtmpfs'
