#!/usr/bin/env python3
"""Build checksum manifests and reproduction archive; verify table regeneration. MIT."""
from pathlib import Path
import hashlib,zipfile,tempfile,subprocess,shutil,json
P=Path(__file__).resolve().parents[1];R=P/'results'
def digest(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def keep(p):
 s=p.relative_to(P)
 if not p.is_file() or any(x in ('.git','__pycache__','.lake') for x in s.parts):return False
 if p.name in ('reproduction.zip','reproduction.zip.sha256','SHA256SUMS','package_run.log'):return False
 if p.suffix in ('.aux','.out','.pyc','.bin'):return False
 if p.name in ('census','naive','transfer.py'):return False
 return True
files=sorted(p for p in P.rglob('*') if keep(p))
(R/'SHA256SUMS').write_text(''.join(f'{digest(p)}  {p.relative_to(R)}\n' for p in files if p.is_relative_to(R)))
files.append(R/'SHA256SUMS');files.sort()
(P/'SHA256SUMS').write_text(''.join(f'{digest(p)}  {p.relative_to(P)}\n' for p in files));files.append(P/'SHA256SUMS')
archive=P/'reproduction.zip'
with zipfile.ZipFile(archive,'w',compression=zipfile.ZIP_DEFLATED,compresslevel=9) as z:
 for p in files:z.write(p,p.relative_to(P))
(P/'reproduction.zip.sha256').write_text(f'{digest(archive)}  reproduction.zip\n')
with tempfile.TemporaryDirectory() as tmp:
 q=Path(tmp)
 with zipfile.ZipFile(archive) as z:z.extractall(q)
 subprocess.run(['sha256sum','-c','SHA256SUMS'],cwd=q,check=True,stdout=subprocess.DEVNULL)
 generated=[p.name for p in (P/'paper').glob('*.tex') if p.name!='multibase_note.tex'];old={n:digest(q/'paper'/n) for n in generated}
 for n in generated:(q/'paper'/n).unlink()
 subprocess.run(['python3','code/make_tables.py'],cwd=q,check=True)
 assert old=={n:digest(q/'paper'/n) for n in generated}
 for i in range(2):subprocess.run(['pdflatex','-interaction=nonstopmode','-halt-on-error','multibase_note.tex'],cwd=q/'paper',check=True,stdout=subprocess.DEVNULL)
 subprocess.run(['python3','code/audit.py'],cwd=q,check=True)
 print('PASS independent extracted ZIP manifest, numerical regeneration (byte-identical includes), twice-built PDF and full audit')
print('ARCHIVE',archive.stat().st_size,'bytes SHA256',digest(archive))
