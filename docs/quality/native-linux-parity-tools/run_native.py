import hashlib,json,os,re,select,shutil,signal,subprocess,sys,tempfile,time,uuid
from pathlib import Path
ROOT=Path(os.environ['TMPDIR']).resolve()/'parity-native'
BROAD=[('linux_fixture_e2e_test.dart',1,None),('linux_http_e2e_test.dart',7,None),('linux_transport_boundary_test.dart',11,None),('linux_maestro_flows_test.dart',20,None),('linux_large_reader_e2e_test.dart',8,None),('linux_persistence_e2e_test.dart',1,'write'),('linux_persistence_e2e_test.dart',1,'verify'),('linux_native_input_e2e_test.dart',4,None),('linux_transcript_export_e2e_test.dart',6,None)]

def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def inputs():
 files=set(subprocess.check_output(['git','ls-files','--cached','--others','--exclude-standard'],text=True).splitlines())
 files.update(('.dart_tool/package_config.json','.dart_tool/package_graph.json'))
 return {f:sha(Path(f)) for f in sorted(files) if Path(f).is_file() and (f.startswith(('lib/','test/','integration_test/','linux/','scripts/','playwright/')) or f in ('pubspec.yaml','pubspec.lock','package.json','package-lock.json','serve_web.mjs','.dart_tool/package_config.json','.dart_tool/package_graph.json'))}
def tools():
 return {f:sha(ROOT/f) for f in ('run_native.py','bin/flutter','env.sh','bounded_bind.c','bounded_bind.so','bin/owned-dbus-daemon','validate_native_harness.py')}
def marked(pid,marker):
 try:return ('WING_PARITY_OWNER='+marker).encode() in Path(f'/proc/{pid}/environ').read_bytes().split(b'\0')
 except (FileNotFoundError,PermissionError,ProcessLookupError):return False
def owned(marker):
 result=[]
 for p in Path('/proc').iterdir():
  if p.name.isdigit() and marked(int(p.name),marker):
   try:result.append({'pid':int(p.name),'command':(p/'comm').read_text().strip()})
   except (FileNotFoundError,ProcessLookupError):pass
 return result
def wait_all(handles,seconds):
 pending=set(handles);deadline=time.monotonic()+seconds
 while pending:
  ready=select.select(list(pending),[],[],max(0,deadline-time.monotonic()))[0]
  pending.difference_update(ready)
  if not ready:break
 return pending
def terminate_owned(marker):
 terminated=[];handles=[]
 try:
  for item in owned(marker):
   try:
    fd=os.pidfd_open(item['pid'])
    if not marked(item['pid'],marker):os.close(fd);continue
    handles.append(fd);signal.pidfd_send_signal(fd,signal.SIGTERM);terminated.append(item)
   except ProcessLookupError:pass
  pending=wait_all(handles,5)
  for fd in pending:
   try:signal.pidfd_send_signal(fd,signal.SIGKILL)
   except ProcessLookupError:pass
  wait_all(pending,5)
 finally:
  for fd in handles:os.close(fd)
 return terminated,owned(marker)
def cleanup_owned(marker,state=None):
 parent=ROOT/'owned-state';states=[]
 if state is not None:states=[state]
 elif marker and parent.exists():
  states=[p for p in parent.iterdir() if p.is_dir() and (p/'.wing-parity-owner').is_file() and (p/'.wing-parity-owner').read_text()==marker]
 terminated,remaining=terminate_owned(marker) if marker else ([],[])
 display_removed=0
 for p in states:
  assert p.parent==parent and p.resolve()==p and p.stat().st_uid==os.getuid()
  assert (p/'.wing-parity-owner').read_text()==marker
  displays=list((p/'tmp').glob('xvfb-run.*'))
  if not remaining:display_removed+=len(displays);shutil.rmtree(p)
 display_remaining=sum(len(list((p/'tmp').glob('xvfb-run.*'))) for p in states if p.exists())
 return {'owned_processes_terminated_after_command':terminated,'owned_processes_remaining':remaining,'owned_display_state_removed_after_command':display_removed,'owned_display_state_remaining':display_remaining,'owned_state_removed':not any(p.exists() for p in states)}
def install_abort_handler(active_marker):
 def abort(signum,frame):
  marker=active_marker[0]
  try:cleanup=cleanup_owned(marker)
  except Exception as error:
   cleanup={'error':type(error).__name__,'owned_state_removed':False,'owned_processes_remaining':owned(marker) if marker else [],'owned_display_state_remaining':None}
  (ROOT/'native-abort.json').write_text(json.dumps({'exit':124,'signal':signum,'marker':marker,'cleanup':cleanup},indent=2)+'\n')
  raise SystemExit(124)
 signal.signal(signal.SIGTERM,abort)
def visible(invocation):return [c for c in invocation['cases'] if not c['hidden']]
def valid_invocation(row):
 return row['exit']==0 and row.get('terminal_success') is True and bool(row.get('bundle_files')) and 'wing' in row['bundle_files'] and all(c['result']=='success' and not c['skipped'] for c in row['cases'])
def validate(invocations,label,command):
 if not all(valid_invocation(x) for x in invocations):return False
 if label=='broad':
  actual=[]
  for x in invocations:
   targets=[Path(a).name for a in x['args'] if a.endswith('_test.dart')]
   if len(targets)!=1:return False
   actual.append((targets[0],len(visible(x)),x.get('persistence_phase')))
  return actual==BROAD
 expected=command[command.index('--plain-name')+1]
 return len(invocations)==1 and len(visible(invocations[0]))==1 and visible(invocations[0])[0]['name']==expected and len(invocations[0].get('native_pids',[]))==1

def commands():
 yield 'broad',['env','-u','DISPLAY','bash','scripts/run_linux_e2e.sh']
 index=0
 for width in ('420.0','1440.0'):
  for name in [f'Maestro session pagination search pin and delete width={width}',f'Maestro exact text and Markdown clipboard exports width={width}',f'Maestro legacy pairing rejection and direct recovery width={width}',f'Maestro gateway is read-only without management width={width}',f'Maestro provider mutations and revoked grants width={width}',f'Maestro draft ownership width={width} delayedPicker=false',f'Maestro draft ownership width={width} delayedPicker=true',f'Maestro approval Stop and offline status recovery width={width}',f'Maestro screen tour on Linux at width {width}',f'Maestro attachments and schedule recovery at width {width}']:
   index+=1
   yield f'scenario-{index:02}',['env','-u','DISPLAY','xvfb-run','-a','flutter','test','--no-pub','-d','linux','integration_test/linux_maestro_flows_test.dart','--plain-name',name,'--reporter','expanded']

def main():
 active_marker=[None];install_abort_handler(active_marker)
 identity={'pid':os.getpid(),'start_ticks':int(Path('/proc/self/stat').read_text().split(') ')[1].split()[19]),'role':'python-runner','command':'run_native.py'}
 (ROOT/'native-runner.identity.json').write_text(json.dumps(identity,indent=2)+'\n')
 source=inputs();tool_hashes=tools();digest=hashlib.sha256(json.dumps(source,sort_keys=True).encode()).hexdigest()
 node_version=subprocess.check_output(['node','--version'],text=True).strip()
 assert node_version.startswith('v22.'),'Use the pinned Node22 fixture runtime'
 runtime={'node_version':node_version,'node_sha256':sha(Path(shutil.which('node'))),'python_version':sys.version.split()[0]}
 (ROOT/'native-source.json').write_text(json.dumps({'files':source,'sha256':digest,'scratch_tools':tool_hashes,'runtime':runtime},indent=2)+'\n')
 parent=ROOT/'owned-state';parent.mkdir(exist_ok=True)
 for label,command in commands():
  marker=uuid.uuid4().hex;state=Path(tempfile.mkdtemp(prefix=label+'-',dir=parent));state.chmod(0o700)
  (state/'.wing-parity-owner').write_text(marker)
  active_marker[0]=marker
  env=dict(os.environ,WING_PARITY_OWNER=marker,WING_PARITY_ARTIFACT_ROOT=str(ROOT))
  for key,folder in [('HOME','home'),('TMPDIR','tmp'),('XDG_CONFIG_HOME','config'),('XDG_DATA_HOME','data'),('XDG_CACHE_HOME','cache'),('XDG_STATE_HOME','local-state'),('XDG_RUNTIME_DIR','runtime')]:
   p=state/folder;p.mkdir(mode=0o700);env[key]=str(p)
  owned_tmp=state/'tmp'
  wrapped=['dbus-run-session','--dbus-daemon='+str(ROOT/'bin/owned-dbus-daemon'),'--',*command]
  print('START',label,flush=True);started=time.time()
  journal=ROOT/'invocations.jsonl';prior=len(journal.read_text().splitlines()) if journal.exists() else 0
  with (ROOT/(label+'.log')).open('w') as out:
   proc=subprocess.Popen(wrapped,stdout=out,stderr=subprocess.STDOUT,env=env,start_new_session=True)
   try:code=proc.wait(timeout=1740 if label=='broad' else 240)
   except subprocess.TimeoutExpired:
    code=124;terminate_owned(marker);proc.wait(timeout=15)
  cleanup=cleanup_owned(marker,state)
  remaining=cleanup['owned_processes_remaining'];display_remaining=cleanup['owned_display_state_remaining']
  invocations=[json.loads(x) for x in journal.read_text().splitlines()[prior:]] if journal.exists() else []
  log=(ROOT/(label+'.log')).read_text()
  receipt={'label':label,'command':command,'exit':code,'seconds':round(time.time()-started,2),'source_sha256':digest,'source_unchanged':source==inputs(),'scratch_tools_unchanged':tool_hashes==tools(),'intended_cases_passed':validate(invocations,label,command),'native_pids':[int(x) for x in re.findall(r'NATIVE_PARITY_PID=(\d+)',log)],'log_sha256':sha(ROOT/(label+'.log')),**cleanup,'invocations':invocations}
  active_marker[0]=None
  with (ROOT/'native-runs.jsonl').open('a') as out:out.write(json.dumps(receipt)+'\n')
  print('END',label,code,'cases',receipt['intended_cases_passed'],'cleanup',not remaining and not display_remaining,flush=True)
  if code or remaining or display_remaining or not receipt['owned_state_removed'] or not receipt['source_unchanged'] or not receipt['scratch_tools_unchanged'] or not receipt['intended_cases_passed']:return 1
 return 0
if __name__=='__main__':sys.exit(main())
