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

/etc/nagios/cgi.cfg:
  file.managed:
    - user: nagios
    - group: nagios
    - mode: '0664'
    - template: jinja
    - source: salt://nagios/server/files/cgi.cfg
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
# Load defaults first
{% set included_yaml_files = [] %}
{% if include_default_files == True %}
  {% do included_yaml_files.extend(default_included_yaml_files) %}
{% endif %}
# Then extend with ones in the pillar
{% do included_yaml_files.extend(nagios.get('included_yaml_files', [])) %}
# Create the dict and merge in the included yaml files.
{% set configs = {} %}
{% for included_yaml_file in included_yaml_files %}
  {% import_yaml included_yaml_file as cfg_file %}
  {% do configs.update(cfg_file) %}
{% endfor %}
# Merge in any additional configs
{% do configs.update(nagios.get('additional_configs', {})) %}
{% set autogenerate_checks = nagios.get('autogenerate_checks', True) %}
{% if autogenerate_checks == True %}
# Load from the pillar first
  {% set autocheck_configs = nagios.get('autocheck_configs', {}) %}
  {% set use_default_autocheck_template = nagios.get('use_default_autocheck_template', True) %}
  {% if use_default_autocheck_template == True %}
    {% import_yaml 'nagios/server/files/conf.d/default_autochecks.yaml' as cfg_file %}
    {% do configs.update(cfg_file) %}
# Default autogen_hosts_file
    {% load_yaml as default_autocheck_cfg %}
      /etc/nagios/conf.d/autogen_hosts.cfg:
        host:
          host_name:
            - use: linux-server
            - host_name: __host_name
            - alias: __alias
            - address: __address
        service:
          nrpe-check-load:
            - use: 'nrpe-check-load'
            - host_name: __host_name
          nrpe-check-users:
            - use: 'nrpe-check-users'
            - host_name: __host_name
          nrpe-check-totprocs:
            - use: 'nrpe-check-totprocs'
            - host_name: __host_name
          nrpe-check-zombie-procs:
            - use: 'nrpe-check-zombie-procs'
            - host_name: __host_name
          nrpe-check-all-disks:
            - use: 'nrpe-check-all-disks'
            - host_name: __host_name
          nrpe-check-swap:
            - use: 'nrpe-check-swap'
            - host_name: __host_name
          nrpe-check-salt-minion:
            - use: 'nrpe-check-salt-minion'
            - host_name: __host_name
    {% endload %}
    {% do autocheck_configs.update(default_autocheck_cfg) %}
  {% endif %}
# Try and limit the number of files created with autogeneration as it 
# has to walk all the grains for all the hosts once per file.
# Plus an additional walk of all the grains to see if the nagios or nagios.nrpe role is defined

# This hack has to do with not being able to get a variable globally that was modified in a
# for loop.  Suggestions on how to improve with a macro or external py renderer are welcome.
  {% load_yaml as process_autoconfig_list %}
    [
    {% for minion_id,minion_grains in salt['mine.get']('*', 'grains.items').items() %}
      {% set minion_roles = minion_grains.get('roles', []) %}
      {% if 'nagios' in minion_roles or 'nagios.nrpe' in minion_roles %}
        True,
      {% endif %}
    {% endfor %}
    ]
  {% endload %}
  {% if True in process_autoconfig_list %}
    {% set process_autoconfig = True %}
  {% else %}
    {% set process_autoconfig = False %} 
  {% endif %}
  {% if process_autoconfig == True %} 
    {% load_yaml as cfg_files %}
      {% for filename,template in autocheck_configs.items() %}
        {{ filename }}:
          {% for object_type, objects in template.items() %}
          {{ object_type }}:
## Is there a sane default here if the mine is not setup?
          {% for minion_id,minion_grains in salt['mine.get']('*', 'grains.items').items() %}
            {% set minion_roles = minion_grains.get('roles', []) %}
            {% if 'nagios' in minion_roles or 'nagios.nrpe' in minion_roles %}
## setup templated items:
              {% set address = minion_grains.get('nagios:address', minion_grains.get('fqdn')) %}
              {% set alias = minion_grains.get('nagios:alias', minion_grains.get('fqdn').replace('.','-')) %}
              {% set host_name = minion_grains.get('nagios:host_name', minion_grains.get('fqdn').replace('.','-')) %}
## save these values to iterate over later.  Will prevent a huge nested if by using a for loop.
              {% for object_name, defines in objects.items() %}
            {{ object_name }}_{{ host_name }}:
                {% for define in defines %}
                  {% set define_name, define_value = define.items()[0] %}
## Super ugly. Find a better way to iterate these.
                  {% set define_value = define_value.replace('__alias', alias) %}
                  {% set define_value = define_value.replace('__host_name', host_name) %}
                  {% set define_value = define_value.replace('__address', address) %}
              - {{ define_name }}: {{ define_value }}  
                {% endfor %}
              {% endfor %}
            {% endif %}
          {% endfor %}
        {% endfor %}
      {% endfor %}
    {% endload %}
    {% do configs.update(cfg_files) %}
  {% endif %}
{% endif %}

# Set directories to be managed by formula. 
{% set cfg_dirs = nagios.get('config:cfg_dirs', []) %}
{% set default_cfg_dirs = ['/etc/nagios', '/etc/nagios/conf.d', '/etc/nagios/objects'] %}
{% for cfg_dir in default_cfg_dirs %}
  {% if cfg_dir not in cfg_dirs %}
    {% do cfg_dirs.extend([cfg_dir]) %}
  {% endif %}
{% endfor %}
{% for cfg_dir in cfg_dirs %}
{{ cfg_dir }}:
  file.directory:
    - user: nagios
    - group: nagios
    - mode: 775
    - makedirs: True
{% endfor %}
# private should have more restricted permissions
/etc/nagios/private:
  file.directory:
    - user: root
    - group: nagios
    - mode: 750
    - makedirs: True
# Create files via the above generated configs
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
