import copy,importlib.util,os,pathlib,subprocess,uuid
root=pathlib.Path(os.environ['TMPDIR'])/'parity-native'
spec=importlib.util.spec_from_file_location('native_runner',root/'run_native.py');m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
def row(target,count,phase=None):
 return {'args':['test','-d','linux','integration_test/'+target],'exit':0,'terminal_success':True,'bundle_files':{'wing':'synthetic-digest'},'persistence_phase':phase,'native_pids':[1],'cases':[{'name':str(i),'result':'success','hidden':False,'skipped':False} for i in range(count)]}
rows=[row(*x) for x in m.BROAD]
assert m.validate(rows,'broad',[])
invalid=[[],rows[:-1]]
for key,value in [('exit',1),('terminal_success',False),('bundle_files',{})]:
 changed=copy.deepcopy(rows);changed[0][key]=value;invalid.append(changed)
for key,value in [('skipped',True),('result','error'),('hidden',True)]:
 changed=copy.deepcopy(rows);changed[0]['cases'][0][key]=value;invalid.append(changed)
for changed in invalid:assert not m.validate(changed,'broad',[])
name='Maestro exact requested case';one=row('linux_maestro_flows_test.dart',1);one['cases'][0]['name']=name
assert m.validate([one],'scenario-01',['--plain-name',name])
wrong=copy.deepcopy(one);wrong['cases'][0]['name']='wrong case'
assert not m.validate([wrong],'scenario-01',['--plain-name',name])
assert not m.validate([one,one],'scenario-01',['--plain-name',name])
# select() may return one ready child at a time; cleanup must drain the set.
originals=(m.owned,m.marked,m.os.pidfd_open,m.os.close,m.signal.pidfd_send_signal,m.select.select)
ready=set();fixtures=[{'pid':pid,'command':'synthetic readiness fixture'} for pid in (1001,1002,1003)]
def one_ready(read,*args):
 fd=min(read);ready.add(fd);return [fd],[],[]
try:
 m.owned=lambda marker:[item for item in fixtures if item['pid'] not in ready]
 m.marked=lambda pid,marker:True;m.os.pidfd_open=lambda pid:pid;m.os.close=lambda fd:None
 m.signal.pidfd_send_signal=lambda fd,sig:None;m.select.select=one_ready
 _,remaining=m.terminate_owned('synthetic readiness fixture')
 assert not remaining, 'parallel cleanup stopped after only one child became ready'
finally:
 m.owned,m.marked,m.os.pidfd_open,m.os.close,m.signal.pidfd_send_signal,m.select.select=originals
marker=uuid.uuid4().hex
owned=subprocess.Popen(['python3','-c','import time; time.sleep(30)'],env=dict(os.environ,WING_PARITY_OWNER=marker))
unrelated=subprocess.Popen(['python3','-c','import time; time.sleep(30)'],env=dict(os.environ,WING_PARITY_OWNER='other-'+marker))
try:
 terminated,remaining=m.terminate_owned(marker)
 assert any(x['pid']==owned.pid for x in terminated) and not remaining
 owned.wait(timeout=5);assert unrelated.poll() is None
finally:
 for p in (owned,unrelated):
  if p.poll() is None:p.terminate()
  p.wait(timeout=5)
probe_code="""import importlib.util,json,os,subprocess,sys,tempfile,time,uuid
from pathlib import Path
root=Path(os.environ['TMPDIR'])/'parity-native'
spec=importlib.util.spec_from_file_location('abort_probe',root/'run_native.py');m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
marker=uuid.uuid4().hex
parent=root/'owned-state';parent.mkdir(exist_ok=True)
state=Path(tempfile.mkdtemp(prefix='abort-probe-',dir=parent));(state/'.wing-parity-owner').write_text(marker)
(state/'tmp/xvfb-run.probe').mkdir(parents=True);(state/'tmp/xvfb-run.probe/Xauthority').write_text('synthetic fixture')
child=subprocess.Popen([sys.executable,'-c','import time;time.sleep(30)'],env=dict(os.environ,WING_PARITY_OWNER=marker))
m.install_abort_handler([marker])
print(json.dumps({'marker':marker,'state':str(state)}),flush=True)
time.sleep(30)
"""
probe=subprocess.Popen(['python3','-c',probe_code],stdout=subprocess.PIPE,text=True)
data=None
try:
 import json
 data=json.loads(probe.stdout.readline());marker=data['marker']
 probe.terminate();assert probe.wait(timeout=15)==124
 assert not m.owned(marker)
 assert not pathlib.Path(data['state']).exists(), 'timeout left owned display/state behind'
 receipt=json.loads((root/'native-abort.json').read_text())
 assert receipt['exit']==124 and receipt['marker']==marker
 assert receipt['cleanup']['owned_state_removed'] and not receipt['cleanup']['owned_processes_remaining']
 assert receipt['cleanup']['owned_display_state_remaining']==0
finally:
 if probe.poll() is None:probe.kill();probe.wait(timeout=5)
 if data:
  import shutil
  m.terminate_owned(data['marker'])
  state=pathlib.Path(data['state'])
  if state.exists() and (state/'.wing-parity-owner').read_text()==data['marker']:shutil.rmtree(state)
  receipt=root/'native-abort.json'
  if receipt.exists() and json.loads(receipt.read_text()).get('marker')==data['marker']:receipt.unlink()
print('Receipt negative controls, pidfd ownership and timeout abort cleanup passed; unrelated fixture preserved.')
