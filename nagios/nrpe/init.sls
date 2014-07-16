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
    - home: /usr/share/nagios
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

{% nrpe = pillar.get('nrpe', {}) %}
{% additional_configs = nrpe.get('additional_configs', {} %}
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
