# Git-Release (BETA - work in progress)

Bash only (language agnostic) git release script for tagging and bagging a release candidate with changelog text generation

[![Build Status](https://travis-ci.org/tommeier/git-release.svg?branch=master)](https://travis-ci.org/tommeier/git-release)

This project performs two simple tasks:

  * Generate a changelog based on git commits and tag with a custom tag prefix
  * Generate a changelog based on git commits at deploy time and tag with a custom deploy tag prefix

Everything is configurable via command line parameters. Run with help command (`-h`) to list all possible configurations.

## Dependencies

  * Git
    * Must be > 2.0 to ensure accurate version sorting
  * Bash (Mac OSX / *nix )
  * Grep
    * Optional:
      * `$EDITOR` set to your editor (eg: `subl --wait`) to edit changelog before tag generated

## Installation

This is the base language agnostic script. Git clone this repo somewhere on your system and ensure the `git-release` and `git-release-deployed` bin files are accessible in the PATH.

## Looking for?

Additional implementations using this base script to wrap functionality and share across languages:

  * Ruby (coming soon)
  * Python (coming soon)
  * Node NPM (coming soon)

## Example flow

The usage flow for this app is as follows:

  * Run `git-release` at the end of a release cycle defining whether it is a major, minor or patch release. This generates a `CHANGELOG` in the root of the projet, and a `VERSION` file with content. If you've released before, this will find the last release and generate changelog and version number accordingly. A tag will be generated for this release with the generated changelog.

  * [Optional][Requires auto push to commit step] During the deploy of this release tag, run `git-release-deployed` on successful deployment. This will generate a new changelog, compared to the last deploy. The reason for this is simple. You may create many releases, but only some versions hit different environments. For example, you create release 0.0.1, deploy to staging, fix many issues, then deploy to production with all the additional fixes. The changelog for staging, for each release, is very different to that of production with all the changes grouped together.

## Version file

This file simply contains the raw version number (e.g. `1.4.21`). Useful for parsing in a deployed app to display the current version number. In some applications I use this to provide a `meta` tag with the version information.

## Changelog file

Generation is based on all git commits between a start and end point ordered by recency. With nothing provided, by default, the scripts will work out the last commit for a tag prefix, or last deploy and generate up to HEAD.

Developers that follow feature branches can pass an optional parameter to generate the changelog only on the pull requests merged in (the 'epics') providing a much cleaner list of content.

Tagged content of the changelog is limited at the moment, I'm looking at ways to make this dynamic. But right now, any commit with the following prefixes (ignoring spaces and case) will group the commits in the `CHANGELOG` and present under ordered (case insensitive) headings:

   * `[Security]`
   * `[Bug]` or `[Bugs]`
   * `[UI Enhancement]` or `[UI Enhancements]`
   * `[Engineering Enhancement]` or `[Engineering Enhancements]`
   * `[Feature]` or `[Features]`

## Deploy

After a deploy running `git-release-deployed` with the release tag passed in provides the ability to generate the changelog based only on the last deploy. With a custom deploy prefix, for example `deployed/staging` you can scope the changelog to a given environment.

## Full examples

### Git-Release

Release with defaults (first time):
```
$> git-release -v 'minor'
```
Generates:
  * version file: `0.1.0`
  * tag         : `releases/v0.1.0`
  * Changelog   : all commits text up until now

---

Release with defaults (second time):
```
$> git-release -v 'major'
```
Generates:
  * version file: `1.0.0`
  * tag         : `releases/v1.0.0`
  * Changelog   : all commits between last release and this one

---

Release with only pull requests for changelog generation:
```
$> git-release -v 'major' -P
```
Generates:
  * version file: `1.0.0`
  * tag         : `releases/v1.0.0`
  * Changelog   : all merged pull requests and the body text of the merge commit

### Additional options:

  * `-U` : Append a github url to each entry in changelog. When combined with `-P` (pull requests) this will be the pull request url.

(TODO: git-release-deployed info)

## Contributing

All fork + pull requests welcome!

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Ensure all tests still run
6. Create new Pull Request

To run the tests locally:

```Bash

$> test/bin/run_all

```

## TODO

 - [ ] Create remaining TODO items as issues in Github
 - [ ] Test mode should display processes it would run (--dry-run option)
 - [ ] Change output of script to hide most output (unless dry run activated)
 - [ ] Create Ruby gem branch and release as a gem. Use better OPTPARSER to use more human readable variables to pass to - der lying  script
 - [ ] Create Node NPM branch and release as an NPM.
 - [ ] Create Python PIP branch and release as a PIP.
 - [ ] Test on variety of systems and servers
 - [ ] [potentially] Fix issue in tests where the time can very rarely cross over a second boundary (make specs ignore seconds difference)
 - [ ] [potentially] Change git-release to work out prefix if given a start or an end point and no prefix
 - [ ] [potentially] Make test helpers for generating the content (changing the style now will break a lot of tests)
 - [ ] [potentially] Make CHANGELOG tagging dynamic (search for initial square brackets), with features + bugs on top of listing
 - [ ] [potentially] Make CHANGELOG generation read in optional template, with wildcards to apply logic to view
 - [ ] [potentially] Work out how to test git push being fired, mocking a git command
 - [ ] [potentially] Use an left pad command to align help text correctly




