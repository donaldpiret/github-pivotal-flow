# History

## 1.4 UNRELEASED
* Change the behavior of git finish for hotfixes to merge back to both the master and the develop branch.

## 1.3
* Fix an issue with mixed-case ssh URL's for git repositories.

## 1.2
* Changed the behavior of Story#merge_to_root! so that it performs non-ff merges and includes the proper commit message to close a story on Pivotal.

## 1.1
* Changed the behavior of Git.create_branch so it does not automatically commit. Branches are not pushed until 'git publish'
* Fixed a bug where the checked out branch would point to a local origin branch instead of the remote.