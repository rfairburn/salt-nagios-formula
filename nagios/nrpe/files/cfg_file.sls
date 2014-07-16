{%- set options = config.get('options', {}) -%}
{%- set commands = config.get('commands', {}) -%}
{% for option_name,option in options.items() -%}
{{ option_name }}={{ option }}
{% endfor -%}
{% for command_name,command in options.items() -%}
command[{{ command_name }}]={{ command }}
{% endfor -%}
