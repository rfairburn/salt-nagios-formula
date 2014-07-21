#!pyobjects

process_autoconfig = False

for minion_id, minion_grains in mine('*', grains.items).items():
  if ('nagios' in minion_grains['roles']) or ('nagios.nrpe' in minion_grains['roles']):
    process_autoconfig = True
