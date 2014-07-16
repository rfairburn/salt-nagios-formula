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
