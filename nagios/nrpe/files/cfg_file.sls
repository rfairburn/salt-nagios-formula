{%- set options = configs.get('options', {}) -%}
{%- set commands = configs.get('commands', {}) -%}
{% for option_name,option in options.items() -%}
{{ option_name }}={{ option }}
{% endfor -%}
{% for command_name,command in options.items() -%}
command[{{ command_name }}]={{ command }}
{% endfor -%}
