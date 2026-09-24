# Bibliography verification

Every citation in the manuscript is verified. No unverifiable citation is included.

| Key | Verified source | Saved evidence |
|---|---|---|
| Hooley, On Artin's conjecture, 1967, J. reine angew. Math. 225, 209–220 | https://api.crossref.org/works/10.1515/crll.1967.225.209 | hooley_crossref.json |
| Moree, Artin's primitive root conjecture—a survey, Integers 12 (2012), no.6, A13 | https://api.crossref.org/works/10.1515/integers-2012-0043 ; https://math.colgate.edu/~integers/vol12a.html | citation_2.json, moree_publisher.html |
| Lemke Oliver–Soundararajan, Unexpected biases in the distribution of consecutive primes, PNAS 113 (2016), no.31 | https://api.crossref.org/works/10.1073/pnas.1605366113 | citation_0.json |
| Tinková–Waxman–Zindulka, Artin twin primes, JNT 245 (2023), 203–232 | https://api.crossref.org/works/10.1016/j.jnt.2022.10.006 ; https://arxiv.org/abs/2010.15988 | citation_1.json; twz_section14.txt |
| J. Bald, Quadratic exclusion laws for consecutive Artin primes in arbitrary bases | https://api.datacite.org/dois/10.5281/zenodo.22865343 | bald_verification.json |
| J. Bald, Correlations of Artin status among primes: consecutive-prime anticorrelation, cross-base entanglement, and an elementary decomposition, consolidated repository | https://github.com/jpbald93/artin-correlations ; https://api.github.com/repos/jpbald93/artin-correlations | consolidated_verification.json, github_readme.txt |

Moree's A13 belongs to the special volume index (vol12a.html), not ordinary vol12.html (where A13 is another article). Both Crossref no.6 and publisher A13 metadata were checked. TWZ §1.4 explicitly fixes a vector of primitive-root bases at distinct shifts; an extracted short passage is saved to support the manuscript's no-novelty statement.

The consolidated repository has an expanded title in its current README. The citation intentionally uses the exact author/title/URL combination required by the author for this note. No new consolidated Zenodo DOI is invented. The Bald exclusion record is verified through DataCite (Zenodo's DOI registry), not Crossref; its absence from Crossref is not a missing DOI.

A preliminary incorrect Hooley DOI lookup returned unrelated authors and was rejected. The correct DOI above was subsequently verified. The preliminary unsuccessful query is not part of the bibliography. The nonabelian discussion is omitted, so there is no ABG citation or data.
