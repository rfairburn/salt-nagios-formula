{% from "nagios/server/map.jinja" import map with context %}

nagios:
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
  file.directory:
    - name: /usr/share/nagios
    - user: nagios
    - group: nagios
    - mode: 755
    - recurse:
      - user
      - group
      - mode
  user:
    - present
    - shell: /bin/false
    - home: /usr/share/nagios 
    - system: true
    - groups:
      - nagios


/etc/nagios/nagios.cfg:
  file.managed:
    - user: nagios
    - group: nagios
    - mode: '0664'
    - template: jinja
    - source: salt://nagios/server/files/nagios.cfg
    - watch_in:
      - service: {{ map.service }}


{% set default_included_yaml_files = ['nagios/server/files/objects/commands.yaml',
                                     'nagios/server/files/objects/contacts.yaml',
                                     'nagios/server/files/objects/localhost.yaml',
                                     'nagios/server/files/objects/printer.yaml',
                                     'nagios/server/files/objects/switch.yaml',
                                     'nagios/server/files/objects/templates.yaml',
                                     'nagios/server/files/objects/timeperiods.yaml',
                                     'nagios/server/files/objects/windows.yaml'] %}
{% set nagios = pillar.get('nagios', {}) %}
{% set include_default_files = nagios.get('include_default_files', True) %}
{% set included_yaml_files = nagios.get('included_yaml_files', []) %}
{% if include_default_files == True %}
  {% do included_yaml_files.extend(default_included_yaml_files) %}
{% endif %}
{% set configs = {} %}
{% for included_yaml_file in included_yaml_files %}
  {% import_yaml included_yaml_file as cfg_file %}
  {% do configs.update(cfg_file) %}
{% endfor %}
{% for file_name,context in configs.items() %}
{{ file_name }}:
  file.managed:
    - user: nagios
    - group: nagios
    - mode: 664
    - template: py
    - source: salt://nagios/server/files/cfg_file.py
    - context:
        configs: 
          {{ context }}
    - watch_in:
      - service: {{ map.service }}
{% endfor %}
