#!/usr/bin/env python3
"""Independent tiny trial division + literal multiplicative orbits; MIT."""
import json,subprocess,math,struct,pathlib
P=pathlib.Path(__file__).resolve().parents[1]; R=P/'results'
def prime(n):return n>=2 and all(n%d for d in range(2,math.isqrt(n)+1))
def root(a,p):
 if a%p==0:return 0
 x=a%p;k=1
 while x!=1:x=x*a%p;k+=1
 return int(k==p-1)
pr=[p for p in range(7,1000) if prime(p)]
bases=[a for a in range(2,106) if all(a%(d*d) for d in range(2,math.isqrt(a)+1))]
sel=[2,3,5,6,7,10,11,13,15,17,21,29]
labels={p:{a:root(a,p) for a in bases} for p in pr}
for block in (2,17,31,1000):
 prefix=R/f'tiny_{block}'
 subprocess.run([str(P/'code/census'),'1000',str(block),'64',str(prefix)],check=True,env={'OMP_NUM_THREADS':'2'})
 data=json.load(open(str(prefix)+'.json'));assert data['n_pairs']==len(pr)-1
 actual=[tuple(map(int,x.split(','))) for x in open(str(prefix)+'.tiny.csv').read().splitlines()[1:]]
 assert actual==[(p,sum(labels[p][a]<<i for i,a in enumerate(bases))) for p in pr]
 for a in bases:
  counts=[0]*4
  for p,q in zip(pr,pr[1:]):counts[2*labels[p][a]+labels[q][a]]+=1
  assert counts==data['bases'][str(a)]
 for a in sel:
  for b in sel:
   counts=[0]*4
   for p,q in zip(pr,pr[1:]):counts[2*labels[p][a]+labels[q][b]]+=1
   assert counts==data['matrix'][f'{a},{b}']
  with open(str(prefix)+f'.channels_{a}.bin','rb') as f:
   aa,M,ng,N=struct.unpack('<4q',f.read(32));raw=f.read();expected={}
   for p,q in zip(pr,pr[1:]):
    index=((p%M)*ng+(q-p)//2-1)*4+2*labels[p][a]+labels[q][a];expected[index]=expected.get(index,0)+1
   found={i:c[0] for i,c in enumerate(struct.iter_unpack('<I',raw)) if c[0]}
   assert found==expected
 print(f'PASS all prime labels, 64 tables, 144 matrix cells and 12 channel arrays; block={block}, including block boundaries')
 for f in R.glob(f'tiny_{block}.channels_*.bin'):f.unlink()
print('PASS independent trial division/orbit implementation; all tests complete')
