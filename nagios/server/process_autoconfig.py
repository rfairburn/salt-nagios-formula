#!py

def run():
  config = {}
  global process_autoconfig = False
  for minion_id, minion_grains in __salt__['mine.get']('*', grains.items).items():
    if ('nagios' in minion_grains['roles']) or ('nagios.nrpe' in minion_grains['roles']):
      process_autoconfig = True
  config = {'process_autoconfig': process_autoconfig}
  return config
