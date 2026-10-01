# Consecutive-prime Artin correlations across squarefree bases

Author: Joshua Bald, independent researcher. ORCID 0009-0002-1317-6489.

Repository: https://github.com/jpbald93/multibase-artin-correlations

**Status:** computational data note. Main manuscript: `paper/multibase_note.pdf` (10 pages). No asymptotic or independent predictive claim is made.

## Contents
- `paper/`: manuscript, generated numerical includes and clean-build PDF.
- `code/`: fresh C/OpenMP enumerators and Python-standard-library analysis/generation/audit scripts.
- `results/`: fresh raw outputs, compressed copies of channel arrays, verification/audit records and SHA256SUMS.
- `reproduction.zip`: stand-alone reproduction package (no source data outside the archive needed to rebuild the numerical displays).

## Rebuild tables and paper from supplied raw results
Requires Python 3 and a normal TeX Live installation with pdflatex, amsmath, amssymb, amsthm, booktabs, longtable, microtype, geometry, hyperref and xurl. `pdfinfo` is needed only for the audit.

```sh
python3 code/make_tables.py
cd paper
pdflatex -interaction=nonstopmode -halt-on-error multibase_note.tex
pdflatex -interaction=nonstopmode -halt-on-error multibase_note.tex
cd ..
python3 code/audit.py
```

The first TeX pass on a fresh extraction can report not-yet-resolved citations; the final pass must have no errors, undefined references, or overfull hboxes. The numerical generator uses only saved JSON/metadata, never results from outside this package. All printed numbers, including identifiers and bibliography, are generated. Numeric TeX formatting arguments and automatic page/section/equation counters are not data.

## Recompute the scientific outputs from scratch
Heavy computations were performed on the author's multi-core workstation (gcc 15.2, 28 OpenMP threads). Independent small-range validation was run separately in pure Python. The following commands can be run on a suitable reproduction machine from this package's root:

```sh
gcc -O3 -Wall -Wextra -fopenmp code/census.c -lm -o code/census   # one harmless -Wmisleading-indentation warning; the source is kept byte-identical to the run that produced the data
gcc -O3 -fopenmp code/naive.c -o code/naive
python3 code/validate.py
OMP_NUM_THREADS=28 code/census 1000000000 1000000 64 results/census_1e9
OMP_NUM_THREADS=28 code/census 10000000000 2000000 15 results/base15_1e10
python3 code/analysis.py
OMP_NUM_THREADS=28 code/naive 1000000 > results/naive_1e6.json
python3 code/make_tables.py
```

These commands replace saved raw outputs; copy the package first if preserving original runtime/checksum evidence matters. The two fresh censuses took about 42 and 39 wall seconds, respectively. The literal-order million-bound check took about 5 seconds. Hardware timings are not portable guarantees.

To rerun only the contraction from compressed channel arrays, first expand them:
```sh
python3 - <<'PY'
import pathlib,gzip
for p in pathlib.Path('results').glob('*.bin.gz'):
    p.with_suffix('').write_bytes(gzip.decompress(p.read_bytes()))
PY
python3 code/analysis.py
```

The main range is **7 <= p < q < 1e9**, yielding **50,847,530** genuine consecutive pairs. The extension gives 455,052,507 pairs. Outputs start at 7, not 5. Starting at 5 would add the single pair (5, 7). No earlier results are used as inputs; every number is computed from the supplied code.

## Raw formats and definitions
- `census_1e9.json`: exact same-base counts and full 12x12 lagged counts; every vector is `[n00,n01,n10,n11]`. Counts correspond to `(Artin_a(p), Artin_b(q))`.
- `base15_1e10.json`: same format for the extended base-15 census. In this single-base mode the census does not evaluate the mixed law, so its `mixed_law` field is a placeholder `[0,0,0]`, not a count. (An independent run at this bound found 0 violations among 67,090,459 eligible pairs; this is not part of the package's outputs.)
- `census_1e9.channels_A.bin.gz`: gzip of little-endian raw channel arrays. Header: four signed 64-bit integers `(base, modulus, gap_slots=150, pair_count)`. Body: unsigned 32-bit counts in `(r,gi,status)` C order, `status=2*X+Y`, gap `g=2*(gi+1)`. There is no overflow bucket: the census asserts `g<=300`. The audit checks every compressed channel file against its recorded SHA256, and checks each header and count sum against `census_1e9.json`.
- `reconstruction.json`: endpoint contractions, empirical/reconstructed deltas, zero-rate AA channels, rigorous Euler-product tail intervals and runtime.
- `exclusions.json`: all 144 ordered residue scans, including empty sets and exact moduli; odd/vacuous shifts excluded.
- `naive_1e6.json`: literal multiplicative-order check, not p-1 factor testing.
- `finite_exceptions.json`: exact endpoint witnesses under both lower-endpoint conventions.
- `editorial_metadata.json`: explicit proof constants, author/licensing identifiers and verified bibliography. These are declared metadata, not claimed sieve measurements.

The statistic is `delta = n11/(n10+n11) - n01/(n00+n01)`; it is directional and not Pearson correlation. The reconstruction assumes conditional independence and takes empirical residue-gap frequencies as INPUT. It is not an out-of-sample prediction or an asymptotic theorem. The Artin product is evaluated through 10,000,000 with a conservative omitted-factor relative bound 1e-7, not claimed accuracy of 1e-15.

## Integrity
`results/SHA256SUMS` covers retained result files; `SHA256SUMS` covers the package source, data and manuscript. `reproduction.zip.sha256` covers the archive itself. Verify inside an extracted archive with `sha256sum -c SHA256SUMS`. After you rebuild the PDF yourself, `paper/multibase_note.pdf` and `paper/multibase_note.log` will no longer match, because pdfTeX embeds a build timestamp; their text content is unchanged. All other files, including every generated numerical include, regenerate byte-identically.

## Licence and assistance
Text: CC BY 4.0, https://creativecommons.org/licenses/by/4.0/ . Code: MIT; see `code/LICENSE`. Numerical data are released under CC BY 4.0 with the text. Bibliographic records/full-text verification excerpts retain their original provenance. AI assistance: the large-language-model assistants GPT-6 Astra and Claude Opus 5.5 (Anthropic), accessed through the Genspark platform, were used in preparing this note, including code, computation, literature search, drafting, review and formalization. The author is responsible for the content.

## Lean formalization of the mixed obstruction
`lean/` is a Lean 4 package (toolchain in `lean/lean-toolchain`, Mathlib pinned in `lean/lake-manifest.json`). It proves the proposition in both orders:
`MixedExclusion.not_primitiveRoot_two_six_of_gap` and `MixedExclusion.not_primitiveRoot_six_two_of_gap`.
```sh
cd lean
lake exe cache get   # downloads the pinned Mathlib build
./gate.sh            # build + no sorry/axiom/native_decide + standard axioms only
```
Expected output: `PASS (4 theorems, standard axioms only)`. The formalization covers the proposition only, not the computations.

`scratch/Satisfiable.lean` gives, for every theorem with hypotheses, a Lean-checked example showing the hypotheses can all be met (compile with `lake env lean scratch/Satisfiable.lean`).
