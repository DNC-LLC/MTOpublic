MTO
===
Reproduction of MTO Final Youth Survey analysis

This file is to be used to collect instructions for steps in the reproduction
and forensic re-analysis of the MTO PTSD results reported in Kessler et al 2014
JAMA paper.  Each analytic step should be documented separately below, with the
sole aim of supporting reproduction of our full analysis by a third party.

A high-level overview of key files and subdirectories in this repository is to
be found (and maintained) at the very bottom of this file.  This is intended to
support an initial appreciation of the repository contents; brief descriptions
of individual files (or suitable groups thereof) should be given in the commit
message accompanying each initial commits.  Thus, a useful brief description of
any committed file should be available through the command:

 `git log -1 --pretty=%s <filename>`

## Reproduction

1. Step one
2. Step two
3. Step three

## Directory Overview

`MTO_for_DNorris.zip`:

This is the original package of SAS code plus documentation provided by Nancy
A. Sampson on behalf of Ronald Kessler, in a 11/13/2014 email to David Norris.

`doc/`:

This directory contains various documents relating to the re-analysis, mainly
from external sources.

`img/`:

This directory contains images for inline use on the project wiki.

`refs/`:

This directory contains relevant literature cited on the project wiki.

#### SAS Scripts

`reanalysis.sas`: Sitting at the top level of our hierarchical script cascade; this script
invokes the 2nd-tier scripts in a 'Makefile'-like manner.

`ptsd_imput_coefs.sas`: Reproduces the NCSR logistic regression analysis that yields the
PTSD imputation model employed in [Kessler et al. 2014 JAMA](#Kessler-2014-JAMA).

`form_cohort.sas`: Reproduces the cohort described in the Study Flow diagram of
[Kessler et al. 2014 JAMA](#Kessler-2014-JAMA).

`ptsd_imput_repro.sas`: Reproduces the original PTSD imputation itself; one of the outputs
is a table of (PPID, log-odds, rand01, imputedPTSD[Y/N]) that will be subjected to further
analysis by David Norris, using R.

