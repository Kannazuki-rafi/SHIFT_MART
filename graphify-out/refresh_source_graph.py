from pathlib import Path
import re,json,hashlib,datetime
root=Path('.')
out=Path('graphify-out')
nodes=[];links=[];files={};functions={};bodies={};seen=set()
def nid(s): return re.sub(r'[^a-zA-Z0-9]+','_',s).strip('_')
def addnode(id,label,file,line=1,kind='symbol'):
 nodes.append({'id':id,'label':label,'source_file':file,'source_location':f'L{line}','file_type':'code' if file.endswith(('.gd','.ps1')) else 'document','type':kind,'_origin':'source-review','confidence':'EXTRACTED','confidence_score':1.0})
def edge(a,b,relation,file,line=1):
 key=(a,b,relation)
 if key in seen:return
 seen.add(key);links.append({'source':a,'target':b,'relation':relation,'source_file':file,'source_location':f'L{line}','_origin':'source-review','confidence':'EXTRACTED','confidence_score':1.0,'weight':1.0})
paths=sorted(list(Path('scripts').rglob('*.gd'))+list(Path('resources').glob('*.gd'))+list(Path('tests').glob('*.gd')))
extras=['SHIFT_MART_GDD.md','README.md','docs/PROGRESS.md','docs/WORK_LOG.md','tests/run_multiplayer.ps1','resources/balance.tres','project.godot']
for path in paths+[Path(p) for p in extras]:
 file=path.as_posix();id=nid(file);files[file]=id;addnode(id,file,file,kind='file')
 if path.suffix!='.gd':continue
 text=path.read_text(encoding='utf-8-sig');matches=list(re.finditer(r'^func\s+(\w+)\s*\(',text,re.M))
 for i,m in enumerate(matches):
  name=m.group(1);fid=id+'__'+name;line=text[:m.start()].count('\n')+1
  functions[(file,name)]=fid;addnode(fid,f'{path.stem}.{name}()',file,line);edge(id,fid,'contains',file,line)
  bodies[(file,name)]=(text[m.start():matches[i+1].start() if i+1<len(matches) else len(text)],line)
 for m in re.finditer(r'^const\s+([A-Z][A-Z_0-9]*)',text,re.M):
  cid=id+'__'+m.group(1);line=text[:m.start()].count('\n')+1;addnode(cid,m.group(1),file,line,'constant');edge(id,cid,'contains',file,line)
 for m in re.finditer(r'res://([^"\n]+)',text):
  target=m.group(1)
  if Path(target).is_file():
   # Reference destinations are added after scanning all files.
   pass
for path in paths:
 file=path.as_posix();text=path.read_text(encoding='utf-8-sig')
 for m in re.finditer(r'res://([^"\n]+)',text):
  target=m.group(1)
  if target in files:edge(files[file],files[target],'references',file,text[:m.start()].count('\n')+1)
for (file,name),(body,line) in bodies.items():
 source=functions[(file,name)]
 for m in re.finditer(r'(?<![\w.])(\w+)\s*\(',body[body.index('\n')+1:]):
  target=functions.get((file,m.group(1)))
  if target:edge(source,target,'calls',file,line)
 for qualifier,targetfile in [('Session','scripts/net/network_session.gd'),('cart','scripts/race/trolley_controller.gd'),('world','scripts/race/race_world.gd')]:
  for m in re.finditer(r'\b'+qualifier+r'\.(\w+)\s*\(',body):
   target=functions.get((targetfile,m.group(1)))
   if target:edge(source,target,'calls',file,line)
# Hand-verified connections that are indirect through button callbacks and signals.
for af,an,bf,bn,rel in [
 ('scripts/app.gd','_main_menu','scripts/app.gd','_solo_debug_drive','binds_button'),
 ('scripts/app.gd','button','scripts/app.gd','_solo_debug_drive','defers_callback'),
 ('scripts/net/network_session.gd','_load','scripts/app.gd','_begin','emits_to'),
 ('scripts/net/network_session.gd','request_shift','scripts/race/race_world.gd','request_shift','emits_to'),
 ('scripts/net/network_session.gd','_snapshot','scripts/race/race_world.gd','_receive','emits_to'),
]:edge(functions[(af,an)],functions[(bf,bn)],rel,af)
for file in ['scripts/race/race_world.gd','scripts/race/trolley_controller.gd','scripts/net/network_session.gd']:
 edge(files[file],files['SHIFT_MART_GDD.md'],'implements_subset',file)
edge(files['tests/run_multiplayer.ps1'],files['scripts/app.gd'],'runs_integration_harness','tests/run_multiplayer.ps1')
for test in ['tests/state_test.gd','tests/solo_test.gd']:
 edge(files[test],files['docs/PROGRESS.md'],'verification_recorded_in',test)
metadata={'updated_at':datetime.datetime.now(datetime.timezone.utc).isoformat(),'project':'SHIFT_MART_3D','method':'Direct source definitions, preload references, local and qualified calls, plus explicitly reviewed callback/signal links. GDScript is unsupported by the installed Graphify AST extractor. Old graph archived in graphify-out/2026-11-09/.','source_hashes':{p.as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for p in paths}}
(out/'graph.json').write_text(json.dumps({'directed':True,'multigraph':False,'graph':metadata,'nodes':nodes,'links':links,'hyperedges':[]},ensure_ascii=False,indent=2),encoding='utf-8')
print(f'Updated source graph: {len(nodes)} nodes, {len(links)} edges, {len(files)} files')
