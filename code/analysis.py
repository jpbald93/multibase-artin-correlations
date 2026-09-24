#!/usr/bin/env python3
"""Stdlib-only first-principles residue scan and empirical-weight reconstruction.
SPDX-License-Identifier: MIT
"""
import math,json,struct,array,pathlib,decimal,time
P=pathlib.Path(__file__).resolve().parents[1]; R=P/'results';R.mkdir(exist_ok=True)
BASES=[2,3,5,6,7,10,11,13,15,17,21,29]
def disc(a):return a if a%4==1 else 4*a
def symbol(a,b):
 if b==0:return int(abs(a)==1)
 k=1
 while b%2==0:
  if a%2==0:return 0
  if a%8 in (3,5):k=-k
  b//=2
 while a:
  while a%2==0:
   a//=2
   if b%8 in (3,5):k=-k
  if a%4==b%4==3:k=-k
  a,b=b%a,a
 return k if b==1 else 0
def delta(c):
 c00,c01,c10,c11=c
 return c11/(c10+c11)-c01/(c00+c01)
def scan():
 out=[]
 for a in BASES:
  for b in BASES:
   L=math.lcm(2,disc(a),disc(b));mask=(1<<L)-1
   unit=sum(1<<r for r in range(L) if math.gcd(r,L)==1)
   A=sum(1<<r for r in range(L) if math.gcd(r,L)==1 and symbol(disc(a),r)==-1)
   B=sum(1<<r for r in range(L) if math.gcd(r,L)==1 and symbol(disc(b),r)==-1)
   gaps=[]
   for g in range(0,L,2):
    U=((unit>>g)|(unit<<(L-g)))&mask
    C=((B>>g)|(B<<(L-g)))&mask
    if unit&U and not A&C:gaps.append(g)
   out.append(dict(a=a,b=b,modulus=L,gaps=gaps))
 proof={str(g):[dict(r=r,s=(r+g)%24,unit=math.gcd(r+g,24)==1,chi=symbol(24,(r+g)%24)) for r in range(1,24,2) if math.gcd(r,24)==1 and symbol(8,r)==-1] for g in (10,14)}
 return dict(pairs=out,proof=proof,diagonal_hits=sum(x['a']==x['b'] and bool(x['gaps']) for x in out),offdiagonal_hits=[x for x in out if x['a']!=x['b'] and x['gaps']])
def prime_list(B):
 s=bytearray(b'\1')*(B+1);s[:2]=b'\0\0'
 for p in range(2,math.isqrt(B)+1):
  if s[p]:s[p*p::p]=b'\0'*((B-p*p)//p+1)
 return [p for p in range(2,B+1) if s[p]]
def reconstruct():
 t=time.monotonic();B=10_000_000;pr=prime_list(B)
 decimal.getcontext().prec=40;D=decimal.Decimal;prod=D(1)
 for q in pr:prod*=1-D(1)/D(q*(q-1))
 # All omitted primes are integers >B, hence sum 1/[q(q-1)] <=1/B.
 low=prod*(1-D(1)/D(B));art=float(prod);out=[]
 for a in BASES:
  with (R/f'census_1e9.channels_{a}.bin').open('rb') as f:
   aa,M,ng,N=struct.unpack('<4q',f.read(32));assert aa==a
   cnt=array.array('I');cnt.frombytes(f.read());assert cnt.itemsize==4
  qs=[q for q in pr if q<=M and M%q==0];tail=art
  for q in qs:tail/=1-1/(q*(q-1))
  v=[]
  for r in range(M):
   x=0.
   if math.gcd(r,M)==1 and symbol(disc(a),r)==-1:
    x=tail
    for q in qs:
     if q>2 and (r-1)%q==0:x*=1-1/q
   v.append(x)
  s1=s2=s12=0.;tot=0;joint=[0]*4;zeroaa=0;zero=[];nonempty=0
  for r in range(M):
   for gi in range(ng):
    i=(r*ng+gi)*4;c=cnt[i:i+4];n=sum(c)
    if not n:continue
    nonempty+=1;tot+=n;g=2*(gi+1);x=v[r];y=v[(r+g)%M]
    s1+=n*x;s2+=n*y;s12+=n*x*y
    for j in range(4):joint[j]+=c[j]
    if x*y==0 and c[3]:zeroaa+=c[3];zero.append(dict(r=r,g=g,AA=c[3]))
  assert tot==N
  p1,p2,p12=s1/N,s2/N,s12/N
  cov=p12-p1*p2
  pred=cov/(p1*(1-p1));scale=1-1/B
  pred_low=scale*cov/(p1*(1-scale*p1))
  emp=delta(joint)
  out.append(dict(a=a,M=M,N=N,joint=joint,delta_emp=emp,delta_rec=pred,ratio=pred/emp,ratio_interval=sorted([pred/emp,pred_low/emp]),delta_rec_interval=sorted([pred,pred_low]),p1=p1,p2=p2,p12=p12,zero_AA=zeroaa,zero_channels=zero,nonempty_channels=nonempty,tail_constant=tail))
 return dict(cutoff=B,decimal_precision=40,Artin_upper=str(prod),Artin_lower=str(low),tail_relative_bound=1/B,seconds=time.monotonic()-t,bases=out)
if __name__=='__main__':
 (R/'exclusions.json').write_text(json.dumps(scan(),indent=2)+'\n')
 (R/'reconstruction.json').write_text(json.dumps(reconstruct(),indent=2)+'\n')
 print('analysis complete')
