#!/usr/bin/env python3
"""Independent arithmetic, provenance, TeX and build audit; MIT."""
import pathlib,json,hashlib,re,subprocess,importlib.util,math,gzip,tempfile,shutil
P=pathlib.Path(__file__).resolve().parents[1];R=P/'results'
def load(n):return json.loads((R/n).read_text())
s=importlib.util.spec_from_file_location('analysis',P/'code/analysis.py');m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
def orbit(a,p):
 if a%p==0:return False
 x=1
 for k in range(1,p):
  x=x*a%p
  if x==1:return k==p-1
pr=m.prime_list(1000);exceptions=[]
for a in m.BASES:
 M=math.lcm(m.disc(a),840)
 for p,q in zip(pr,pr[1:]):
  if p<5:continue
  if (math.gcd(p,M)>1 or math.gcd(q,M)>1) and orbit(a,p) and orbit(a,q):exceptions.append(dict(base=a,p=p,q=q,in_reported_range=p>=7))
assert exceptions==[dict(base=3,p=5,q=7,in_reported_range=False),dict(base=17,p=5,q=7,in_reported_range=False),dict(base=17,p=7,q=11,in_reported_range=True)]
(R/'finite_exceptions.json').write_text(json.dumps(exceptions,indent=2)+'\n')
for z in load('exclusions.json')['pairs']:
 a,b,L=z['a'],z['b'],z['modulus'];U=[r for r in range(L) if math.gcd(r,L)==1];found=[]
 # Independent explicit nested residue enumeration, not cyclic bitsets.
 for g in range(0,L,2):
  valid=[r for r in U if math.gcd(r+g,L)==1]
  if valid and not any(m.symbol(m.disc(a),r)==m.symbol(m.disc(b),(r+g)%L)==-1 for r in valid):found.append(g)
 assert found==z['gaps']
print('PASS explicit residue enumeration agrees with the bitset scan on all ordered pairs')
for q in pr[1:]:
 for a in range(2,106):assert m.symbol(m.disc(a),q)==(0 if a%q==0 else 1 if pow(a,(q-1)//2,q)==1 else -1)
print('PASS quadratic symbols versus Euler criterion; finite exceptional endpoints via literal orders')
small=[p for p in pr if 7<=p<1000];eligible=[(p,q) for p,q in zip(small,small[1:]) if (q-p)%24 in (10,14)]
nt=load('naive_tiny.json');assert nt['pairs']==len(small)-1 and nt['eligible']==len(eligible)
assert sum(orbit(2,p)*orbit(6,q) for p,q in eligible)==nt['violations26']==0
assert sum(orbit(6,p)*orbit(2,q) for p,q in eligible)==nt['violations62']==0
print('PASS naive C tiny output versus independent Python literal-order implementation')
c=load('census_1e9.json');assert c['n_pairs']==50847530
assert len(c['bases'])==64
for z in load('reconstruction.json')['bases']:
 assert z['joint']==c['bases'][str(z['a'])]
 assert abs(z['delta_emp']-m.delta(z['joint']))<1e-15
 assert abs(z['delta_rec']-(z['p12']-z['p1']*z['p2'])/(z['p1']*(1-z['p1'])))<1e-15
print('PASS reconstruction formula equals implemented and saved contraction; same-base and matrix diagonals agree')
for z in load('reconstruction.json')['bases']:
 assert len({f'{v:.6f}' for v in z['delta_rec_interval']})==1
 assert len({f'{v:.4f}' for v in z['ratio_interval']})==1
print('PASS rigorous product tail intervals preserve every printed reconstruction digit')
for a,v in c['bases'].items():
 if a+','+a in c['matrix']:assert v==c['matrix'][a+','+a]
text=(P/'paper/multibase_note.tex').read_text()
for pattern in [r'Paper[~ ]*[4-8]',r'multiplicatively dependent',r'non-?zero limit',r'all 64 non-?square',r'only negative pairs are',r'\bVM\b',r'remote machine',r'gmktec',r'\bjack\b']:
 assert not re.search(pattern,text,re.I),pattern
# 'significan*' and 'certif*' are allowed only in the single explicit disclaimer sentence
flat=' '.join(text.split())
allowed=['or claims that a descriptive score certifies a sign']
scrub=flat
for a in allowed:scrub=scrub.replace(a,'')
for pattern in [r'significan',r'certif',r'sign criterion(?! or a rule)']:
 assert not re.search(pattern,scrub,re.I),pattern
for i,line in enumerate(text.splitlines(),1):
 if re.search(r'\d',line):
  assert line.startswith(('\\documentclass','\\usepackage','\\setlength','\\input{matrix_')),f'handwritten numeral line {i}: {line}'
print('PASS manuscript no hand-typed printed numerals; only numeric TeX formatting/file arguments')
with tempfile.TemporaryDirectory() as tmp:
 q=pathlib.Path(tmp)
 for d in ('code','results','paper'):shutil.copytree(P/d,q/d,ignore=shutil.ignore_patterns('*.bin','__pycache__'))
 gen=[p.name for p in (P/'paper').glob('*.tex') if p.name!='multibase_note.tex']
 for n in gen:(q/'paper'/n).unlink()
 subprocess.run(['python3','code/make_tables.py'],cwd=q,check=True,stdout=subprocess.DEVNULL)
 for n in gen:assert (q/'paper'/n).read_bytes()==(P/'paper'/n).read_bytes(),f'generated include differs from make_tables.py output: {n}'
print('PASS every shipped numerical include equals a fresh make_tables.py regeneration')
log=(P/'paper/multibase_note.log').read_text()
assert not any(s in log for s in ('Overfull \\hbox','undefined','! LaTeX Error','! Emergency stop'))
print('PASS final TeX log: no errors, undefined references or overfull hboxes')
info=subprocess.check_output(['pdfinfo',str(P/'paper/multibase_note.pdf')],text=True);pages=int(re.search(r'Pages:\s*(\d+)',info)[1]);assert 8<=pages<=14;print('PASS page count',pages)
# every raw output matches the SHA256 recorded when it was produced; nothing may be skipped
checked=0
for f in ('compute_execution.log','analysis_execution.log'):
 for line in (R/f).read_text().splitlines():
  ss=line.split()
  if len(ss)==2 and re.fullmatch('[0-9a-f]{64}',ss[0]):
   name=pathlib.Path(ss[1]).name
   cand=[R/name,P/'code'/name,P/ss[1]]
   target=next((c for c in cand if c.exists()),None)
   if target is not None:data=target.read_bytes()
   elif (R/(name+'.gz')).exists():data=gzip.decompress((R/(name+'.gz')).read_bytes())
   else:raise AssertionError(f'logged output missing from package: {ss[1]}')
   assert hashlib.sha256(data).hexdigest()==ss[0],f'hash mismatch: {ss[1]}'
   checked+=1
assert checked>=24,checked
print('PASS raw-output SHA256 verification',checked,'files, none skipped')
# channel headers and count sums against census_1e9.json
import struct
for gz in sorted(R.glob('census_1e9.channels_*.bin.gz')):
 raw=gzip.decompress(gz.read_bytes());base,mod,slots,npairs=struct.unpack('<4q',raw[:32])
 assert slots==150 and npairs==c['n_pairs'],gz.name
 body=struct.unpack(f'<{(len(raw)-32)//4}I',raw[32:]);assert len(body)==mod*slots*4,gz.name
 tot=[0,0,0,0]
 for i,v in enumerate(body):tot[i%4]+=v
 assert tot==c['bases'][str(base)],gz.name
print('PASS channel headers and per-status count sums equal the census tables')
