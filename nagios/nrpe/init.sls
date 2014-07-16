
nstalled
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

/etc/nrpe:
  file.managed:
    - recurse
    - source: salt://nagios/nrpe/files
    - template: jinja
    - watch_in:
      - service: {{ map.service }}
    - user: nrpe
    - group: nrpe
