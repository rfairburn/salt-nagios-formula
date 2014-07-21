{% from "nagios/nrpe/map.jinja" import map with context %}

nrpe:
  pkg:
    - installed
    - pkgs: {{ map.pkgs|json }}
  service:
    - running
    - name: {{ map.service }}
    - enable: true
  group:
    - present
    - system: true
  user:
    - present
    - shell: /bin/false
    - home: '/var/run/nrpe'
    - groups:
      - nrpe

/etc/nagios/nrpe.cfg:
  file.managed:
    - source: salt://nagios/nrpe/files/nrpe.cfg
    - template: jinja
    - watch_in:
      - service: {{ map.service }}
    - user: nrpe
    - group: nrpe

{% set nrpe = pillar.get('nrpe', {}) %}
{% set additional_configs = {} %}
{% set use_default_autocheck_template = nrpe.get('use_default_autocheck_template', True) %}
{% if use_default_autocheck_template == True %}
# get all nagios servers
  {% load_yaml as allowed_hosts %}
    [
    {% for minion_id, minion_grains in salt['mine.get']('*', grains.items).items() %}
      {% if 'nagios' in minion_roles or 'nagios.nrpe' in minion_roles %}
        {{ minion_grains.get('ipv4')[0] }},
      {% endif %}
    {% endfor %}
    ]
  {% endload %}
  {% load_yaml as additional_config %}
/etc/nrpe.d/_default_autochecks.cfg:
  options:
    allowed_hosts: {{ allowed_hosts|join(',') }}
  commands:
    check_all_disks: '/usr/lib64/nagios/plugins/check_disk -w 20 -c 10 -A -l -X tmpfs -X devtmpfs'
    check_total_procs: '/usr/lib64/nagios/plugins/check_procs -w 150 -c 200'
    check_load: '/usr/lib64/nagios/plugins/check_load -w 15,10,5 -c 30,25,20'
    check_users: '/usr/lib64/nagios/plugins/check_users -w 5 -c 10'
    check_zombie_procs: '/usr/lib64/nagios/plugins/check_procs -w 5 -c 10 -s Z'
    check_salt_minion: '/usr/lib64/nagios/plugins/check_procs -w 1:1 -c 1:1 -C salt-minion -u root'
  {% endload %}
{% endif %}
{% do additional_configs.update(additional_config) %}
{% do additional_configs.update( nrpe.get('additional_configs', {})) %}
# FIXME: probably should support external yaml files like the main nagios configs
# but these will typically be much smaller files
{% for file_name,context in additional_configs.items() %}
{{ file_name }}:
  file.managed:
    - user: nrpe
    - group: nrpe
    - mode: 664
    - template: jinja
    - source: salt://nagios/nrpe/files/cfg_file.sls
    - context:
        configs:
          {{ context }}
    - watch_in:
      - service: {{ map.service }}
{% endfor %}
