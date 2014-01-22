# Github Pivotal Flow

`github-pivotal-flow` provides a set of additional Git commands to help developers when working with [Pivotal Tracker][pivotal-tracker], git-flow and Github pull requests.
It follows the branch structure recommended by [Git flow][git-flow].

This is the tool we use internally to speed up our development process.

[pivotal-tracker]: http://www.pivotaltracker.com
[git-flow]: https://github.com/nvie/gitflow

## Installation
`github-pivotal-flow` requires at least **Ruby 1.9.3**, **Git 1.8.2.1** in order to run.  It is tested against Rubies _1.9.3_, _2.0.0_ and _2.1.0_.  In order to install it, do the following:

```plain
$ gem install github-pivotal-flow
```


## Usage
`github-pivotal-flow` is intended to vastly speed up your development workflow.
The typical workflow looks something like the following:

```plain
$ git start       # Creates branch, opens a pull request on Github and starts story
$ git commit ...
$ git commit ...  # Your existing development process
$ git commit ...
$ git finish      # Merges back into the main branch. Pushes to origin, destroys branch and finishes story.
```


## Configuration

### Git Client
In order to use `github-pivotal-flow`, a few Git client configuration properties must be set.  If these properties have not been set, you will be prompted for them and your Git configuration will be updated.

| Name | Description
| ---- | -----------
| `pivotal.api-token` | Your Pivotal Tracker API Token.  This can be found in [your profile][profile] and should be set globally.
| `pivotal.project-id` | The Pivotal Tracker project id for the repository your are working in.  This can be found in the project's URL and should be set.
| `gitflow.branch.master` | The Git-flow master branch name. If you've used Git-flow before this will already be set up. Otherwise this is the branch considered 'production'.
| `gitflow.branch.development` | The Git-flow development branch name. The branch that is commonly used for your development.
| `gitflow.prefix.feature` | Git-flow feature branch name prefix.
| `gitflow.prefix.hotfix` | Git-flow hotfix branch name prefix.
| `gitflow.prefix.feature` | Git-flow feature branch name prefix.
| `gitflow.prefix.release` | Git-flow release branch name prefix.

[profile]: https://www.pivotaltracker.com/profile


### Git Server
In order to take advantage of automatic issue completion, the [Pivotal Tracker Source Code Integration][integration] must be enabled.  If you are using GitHub, this integration is easy to enable by navgating to your project's 'Service Hooks' settings and configuring it with the proper credentials.

[integration]: https://www.pivotaltracker.com/help/integrations?version=v3#scm


## Commands

### `git start [ type | story-id ]`
This command starts a story by creating a Git branch, opening a pull-request on Github and changing the story's state to `started`.
This command can be run in three ways.  First it can be run specifying the id of the story that you want to start.

```plain
$ git start 12345678
```

The second way to run the command is by specyifying the type of story that you would like to start.  In this case it will then offer you the first five stories (based on the backlog's order) of that type to choose from.

```plain
$ git start feature

1. Lorem ipsum dolor sit amet, consectetur adipiscing elit
2. Pellentesque sit amet ante eu tortor rutrum pharetra
3. Ut at purus dolor, vel ultricies metus
4. Duis egestas elit et leo ultrices non fringilla ante facilisis
5. Ut ut nunc neque, quis auctor mauris
Choose story to start:
```

Finally the command can be run without specifying anything.  In this case, it will then offer the first five stories (based on the backlog's order) of any type to choose from.

```plain
$ git start

1. FEATURE Donec convallis leo mi, dictum ornare sem
2. CHORE   Sed et magna lectus, sed auctor purus
3. FEATURE In a nunc et enim tincidunt interdum vitae et risus
4. FEATURE Fusce facilisis varius lorem, at tristique sem faucibus in
5. BUG     Donec iaculis ante neque, ut tempus augue
Choose story to start:
```

Once a story has been selected by one of the three methods, the command then prompts for the name of the branch to create.

```plain
$ git start 12345678
        Title: Lorem ipsum dolor sit amet, consectetur adipiscing elitattributes
  Description: Ut consequat sapien ut erat volutpat egestas. Integer venenatis lacinia facilisis.

Enter branch name (feature/12345678-<branch-name>):
```

The value entered here will be prepended with the story id such that the branch name is `<story-type-prefix>/<story-id>-<branch-name>`.  This branch is then created and checked out.

If it doesn't exist already, a `prepare-commit-msg` commit hook is added to your repository.  This commit hook augments the existing commit messsage pattern by appending the story id to the message automatically.

```plain

[#12345678]
# Please enter the commit message for your changes. Lines starting
# with '#' will be ignored, and an empty message aborts the commit.
# On branch 12345678-lorem-ipsum
# Changes to be committed:
#   (use "git reset HEAD <file>..." to unstage)
#
#	new file:   dolor.txt
#
```

### `git finish [--no-complete]`
This command finishes a story by merging and cleaning up its branch and then pushing the changes to a remote server.
This command can be run in two ways.  First it can be run without the `--no-complete` option.

```plain
$ git finish
Checking for trivial merge from feature/63805340-sample_feature to development... OK
Merging feature/63805340-sample_feature to development... OK
Deleting feature/63805340-sample_feature... OK
```

The command checks that it will be able to do a trivial merge from the development branch to the target branch before it does anything.
The check has the following constraints

1.  The local repository must be up to date with the remote repository (e.g. `origin`)
2.  The local merge target branch (e.g. `development`) must be up to date with the remote merge target branch (e.g. `origin/development`)
3.  The common ancestor (i.e. the branch point) of the development branch (e.g. `feature/12345678-lorem-ipsum`) must be tip of the local merge target branch (e.g. `development`)

If all of these conditions are met, the development branch will be merged into the target branch with a message of:

```plain
Merge feature/12345678-lorem-ipsum to development

[Completes #12345678]
```

The second way is with the `--no-complete` option specified.
In this case `finish` performs the same actions except the `Completes`... statement in the commit message will be supressed.

```plain
Merge feature/12345678-lorem-ipsum to development

[#12345678]
```

After merging, the development branch is deleted and the changes are pushed to the remote repository.

