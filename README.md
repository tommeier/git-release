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
 - [ ] Change releaseable to work out prefix if given a start or an end point
 - [ ] Remove unnessary $(output)= statements in tests
 - [ ] Remove the 'skip execute' code
 - [ ] Optionally force push of tags, otherwise ask for confirmation to send
 - [ ] Make uniform variable style, either all capped variables or not
 - [ ] Test mode should display processes it would run (--dry-run option)
 - [ ] Verbose debug mode (display a lot more info)
 - [ ] Create Ruby gem branch and release as a gem. Use better OPTPARSER to use more human readable variables to pass to - der lying  script
 - [ ] Create Node NPM branch and release as an NPM.
 - [ ] Create Python PIP branch and release as a PIP.
 - [ ] Test on variety of systems and servers
 - [ ] Fix issue in tests where the time can very rarely cross over a second boundary (make specs ignore seconds difference)
 - [ ] Review argument naming and choose better letters
 - [ ] Make test helpers for setting argument mapping (for easily changing in other wrappers)
 - [ ] Make test helpers for generating the content (changing the style now will break a lot of tests)
 - [ ] [potentially] Make CHANGELOG tagging dynamic (search for initial square brackets), with features + bugs on top of listing
 - [ ] [potentially] Make CHANGELOG generation read in optional template, with wildcards to apply logic to view
 - [*] Update releaseable to remove the division of release and version prefix, make just one prefix (simpler)
 - [x] Write success cases for releaseable-deployed script
 - [*] Split up functions and specs into more logical divisions (changelog, git) rather than one large support file
 - [*] Remove *.sh filenames and rely on shebangs on each executable file. Support files keep for editors to use.
 - [*] Split into seperate github repo with migrated history
 - [*] Load Travis-CI





