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

# Possibly have it watch apache service for passwd?
# Would make an apache formula a dependency.
/etc/nagios/passwd:
  file.managed:
    - user: root
    - group: apache
    - mode: '0640'
    - template: jinja
    - source: salt://nagios/server/files/passwd

/etc/nagios/private/resource.cfg:
  file.managed:
    - user: nagios
    - group: nagios
    - mode: '0660'
    - template: jinja
    - source: salt://nagios/server/files/private/resource.cfg
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
{% set configs = nagios.get('additional_configs', {}) %}
{% for included_yaml_file in included_yaml_files %}
  {% import_yaml included_yaml_file as cfg_file %}
  {% do configs.update(cfg_file) %}
{% endfor %}
{% set autogenerate_checks = nagios.get('autogenerate_checks', True) %}
{% if autogenerate_checks == True %}
# Load from the pillar first
  {% set autocheck_configs = nagios.get('autocheck_configs', {}) %}
  {% set use_default_autocheck_template = nagios.get('use_default_autocheck_template', True) %}
  {% if use_default_autocheck_template == True %}
    {% import_yaml 'nagios/server/files/objects/default_autochecks.yaml' as cfg_file %}
    {% do configs.update(cfg_file) %}
# Default autogen_hosts_file
    {% load_yaml as default_autocheck_cfg %}
      /etc/nagios/objects/autogen_hosts.cfg:
        host:
          host_name:
            use: linux-server
            host_name: __host_name
            alias: __alias
            address: __address
        service:
          check-load:
            use: 'check-load'
            host_name: __host_name
          check-users:
            use: 'check-users'
            host_name: __host_name
          check-totprocs:
            use: 'check-totprocs'
            host_name: __host_name
          check-zombie-procs:
            use: 'check-zombie-procs'
            host_name: __host_name
          check-all-disks:
            use: 'check-all-disks'
            host_name: __host_name
          check-swap:
            use: 'check-swap'
            host_name: __host_name
    {% endload %}
    {% do autocheck_configs.update(default_autocheck_cfg) %}
  {% endif %}
# Try and limit the number of files created with autogeneration as it 
# has to walk all the grains for all the hosts once per file.
  {% load_yaml as cfg_files %}
    {% for filename,template in autocheck_configs.items() %}
      {{ filename }}:
## Is there a sane default here if the mine is not setup?
      {% for minion_id,minion_grains in salt['mine.get']('*', 'grains.items').items() %}
## setup templated items:
        {% set address = minion_grains.get('nagios:address', minion_grains.get('ipv4')[0]) %}
        {% set alias = minion_grains.get('nagios:alias', minion_grains.get('fqdn').replace('.','-')) %}
        {% set host_name = minion_grains.get('nagios:host_name', minion_grains.get('fqdn').replace('.','-')) %}
## save these values to iterate over later.  Will prevent a huge nested if by using a for loop.
        {% set template_replacements = {'__address': address, '__alias': 'alias', '__hostname': 'hostname'} %}
        {% for object_type, objects in template.items() %}
        {{ object_type }}:
          {% for object_name, defines in objects.items() %}
          {{ object_name }}:
            {% for define_name,define_value in defines.items() %}
              {% for replacement_name, replacement_value in template_replacements.items() %}
                {% set define_value = define_value.replace(replacement_name, replacement_value) %}  
                {% set define_name = define_name|upper %}
              {% endfor %}
#            {% set define_value = define_value.replace('__address', address) %}
            {{ define_name }}: {{ define_value }}  
            {% endfor %}
          {% endfor %}
        {% endfor %}
      {% endfor %}
    {% endfor %}
  {% endload %}
  {% do configs.update(cfg_files) %}
### TEMPORARY ###
  {% set configs = cfg_files %}
{% endif %}

/tmp/test.txt:
  file.managed:
    - user: nagios
    - group: nagios
    - mode: 664
    - contents:
        {{ configs|json }}

#{% for file_name,context in configs.items() %}
#{{ file_name }}:
#  file.managed:
#    - user: nagios
#    - group: nagios
#    - mode: 664
#    - template: py
#    - source: salt://nagios/server/files/cfg_file.py
#    - context:
#        configs: 
#          {{ context }}
#    - watch_in:
#      - service: {{ map.service }}
#{% endfor %}
