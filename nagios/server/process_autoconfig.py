#!pyobjects

value_process_autoconfig = False
for minion_id, minion_grains in __salt__['mine.get']('*', grains.items).items():
  if ('nagios' in minion_grains['roles']) or ('nagios.nrpe' in minion_grains['roles']):
    value_process_autoconfig = True

class process_autoconfig(Map):
  process_autoconfig = value_process_autoconfig

