# CRAN submission runbook

Step-by-step path from this repo to a CRAN release. Steps marked
**FOUNDER** need Jacob personally (CRAN requires maintainer email
confirmations that nobody else can click).

## 0. One-time prerequisites

- The maintainer email in `DESCRIPTION` (`jgalperi@ramapo.edu`) must be
  an inbox Jacob reads: CRAN sends a confirmation link there at
  submission and every future update goes through it. If a different
  address is preferred, change `Authors@R` before submitting.
- Install R locally (CRAN submission needs local builds):
  `brew install --cask r` on a Mac with headroom, not the 8GB Air.

## 1. Pre-submission checklist

```r
install.packages(c("devtools", "urlchecker", "spelling"))

devtools::document()          # regenerate man/ and NAMESPACE
devtools::build_readme()      # only if a README.Rmd is ever added
urlchecker::url_check()       # all URLs must resolve
spelling::spell_check_package()
devtools::check(remote = TRUE, manual = TRUE)  # local R CMD check
```

Must be: 0 errors, 0 warnings. NOTEs need justification in
`cran-comments.md`. Expected NOTE on first submission: "New
submission".

CRAN policy points this package already handles, verify they stayed
true:

- No network access in examples, tests, or vignette on CRAN machines:
  network examples are `\donttest{}`/`\dontrun{}`, live tests use
  `skip_on_cran()` + `skip_if_offline()`, the vignette self-disables
  when the API is unreachable. Do not remove those guards.
- Examples run in under 5 seconds each.
- No writing to the user's filesystem.

## 2. Version and metadata

- Set a release version in `DESCRIPTION` (e.g. `0.1.0`).
- Update `NEWS.md`.
- Create `cran-comments.md` (kept out of the build via
  `.Rbuildignore`):

```
## R CMD check results
0 errors | 0 warnings | 1 note
* This is a new submission.
## Test environments
- local macOS, R release
- GitHub Actions ubuntu-latest, R release
- win-builder (devel)
```

## 3. Remote checks

```r
devtools::check_win_devel()   # win-builder, results emailed **FOUNDER**
```

Optionally also R-hub v2: `rhub::rhub_check()` (runs on GitHub
Actions, needs the repo, which we have).

## 4. Submit

```r
devtools::release()
```

This walks the checklist, builds the tarball, uploads to
<https://cran.r-project.org/submit.html>, and then:

- **FOUNDER**: CRAN emails a confirmation link to the maintainer
  address. The submission does not enter the queue until it is
  clicked.
- **FOUNDER**: watch for CRAN reviewer replies (usually within days
  for a new package). Respond politely, fix, resubmit with an
  incremented version and a note in `cran-comments.md` describing the
  changes.

## 5. After acceptance

- Tag the release: `git tag v0.1.0 && git push --tags`.
- Add the CRAN badge to README:
  `[![CRAN status](https://www.r-pkg.org/badges/version/parlayapiR)](https://CRAN.R-project.org/package=parlayapiR)`
- Update install instructions to `install.packages("parlayapiR")`.
- CRAN runs its own checks continuously; breakages (e.g. an API change
  that affects the vignette guard) must be fixed within CRAN's stated
  deadline or the package gets archived. The vignette and test guards
  make this unlikely, but keep the maintainer inbox monitored.
