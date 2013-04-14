# Releaseable (BETA - work in progress)

Bash only (language agnostic) git release script for tagging and bagging a release candidate with changelog text generation

[![Build Status](https://travis-ci.org/tommeier/releaseable.png)](https://travis-ci.org/tommeier/releaseable)

*add full description*

*add full examples*

*add contribution section (how to test)*

## Dependencies

  * Git
  * Bash (Mac OSX / *nix )
  * Grep

## TODO

 - [ ] Write a proper README
 - [ ] Test mode should display processes it would run (--dry-run option)
 - [ ] Change output of script to hide most output (unless dry run activated)
 - [ ] Create Ruby gem branch and release as a gem. Use better OPTPARSER to use more human readable variables to pass to - der lying  script
 - [ ] Create Node NPM branch and release as an NPM.
 - [ ] Create Python PIP branch and release as a PIP.
 - [ ] Test on variety of systems and servers
 - [ ] [potentially] Fix issue in tests where the time can very rarely cross over a second boundary (make specs ignore seconds difference)
 - [ ] [potentially] Change releaseable to work out prefix if given a start or an end point and no prefix
 - [ ] [potentially] Make test helpers for generating the content (changing the style now will break a lot of tests)
 - [ ] [potentially] Make CHANGELOG tagging dynamic (search for initial square brackets), with features + bugs on top of listing
 - [ ] [potentially] Make CHANGELOG generation read in optional template, with wildcards to apply logic to view
 - [ ] [potentially] Work out how to test git push being fired, mocking a git command
 - [ ] [potentially] Use an left pad command to align help text correctly
 - [*] Optionally force push of tags, otherwise ask for confirmation to send
 - [*] Remove the 'skip execute' code
 - [*] Create language maps (bash first, to make ruby only etc) for argument naming. Use everywhere in specs
 - [*] Make test helpers for setting argument mapping (for easily changing in other wrappers)
 - [*] Review argument naming and choose better letters
 - [*] Remove unnessary $(output)= statements in tests
 - [*] Update releaseable to remove the division of release and version prefix, make just one prefix (simpler)
 - [*] Write success cases for releaseable-deployed script
 - [*] Split up functions and specs into more logical divisions (changelog, git) rather than one large support file
 - [*] Remove *.sh filenames and rely on shebangs on each executable file. Support files keep for editors to use.
 - [*] Split into seperate github repo with migrated history
 - [*] Load Travis-CI





