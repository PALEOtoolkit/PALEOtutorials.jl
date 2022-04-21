# Minimal git workflow for scientific collaboration and reproducibility

There are many online resources for git (see eg <https://git-scm.com/doc>).

This HOWTO illustrates a minimal git workflow, sufficient to enable scientific collaboration:
1. install git
2. figure out github authentication
3. clone PALEO repository
4. choose an existing branch to contribute to, or to use as a starting point with a new branch for your work
5. make changes and commit
6. push the new branch to the PALEO repository
7. fetch and merge changes made by a collaborator

This is already enough to enable collaboration by sharing model configurations and updates,
and to archive configurations etc on github to provide reproducibility.

The key step here is to *create a new branch*: provided you do this, your changes won't interfere
with anyone elses, and can be shared to github.

Much of the complexity of using git is dealing with what happens next in a software development context:
how to merge and combine changes back into a single codebase. But this isn't essential for scientific collaboration.
If needed, the next step is:

8\.  Create a [pull request](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/creating-a-pull-request) on github.com to propose and collaborate on making changes to the core PALEO code.

## Install git

Download from <https://git-scm.com/downloads>

This HOWTO uses a minimum installation of the command line git tools. Other tools are available,
including GUIs. Git is also built-in to VS Code.

To get basic help for the command line tools:

    git help

## Github authentication

There are (since ~mid 2021) now two steps needed:
- github.com website uses username/password
- code access requires a 'Personal Access Token' (PAT) <https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token>
  NB: not all git tools are updated to reflect this, and will prompt for 'password' where what they need is 'PAT'.

## Clone github repository
To download <https://github.com/sjdaines/PALEOdev.jl> into a new folder `PALEOjulia`:

    git clone https://github.com/sjdaines/PALEOdev.jl PALEOjulia

See above for PAT, not password. 

## Create branch

Change directory to 'PALEOjulia', then:

To show the current branch ('master'):

    git status

To show all branches in the repository:

    git branch -a

or to just show existing local branches:

    git branch 

To create a local branch corresponding to an existing branch on github (synchronized via a 'remote tracking branch'):

    git checkout -b <existing branch> --track origin/<existing branch>

(this is needed eg if you clone the github.com repository to a new folder, and then want to contribute to or start from an existing branch)

To change to an existing local branch:

    git checkout <existing branch>

To create a new branch for your work (branching from the current branch), and then check it out:

    git branch <my new branch>
    git checkout <my new branch>

## Commit changes

To add modified or new files:

    git add <modified and new files>

To check everything added:

    git status

To commit changes:

    git commit -m "add a useful summary of changes here"

## Push changes to github

To push changes in the current branch to github:

    git push

if you then go to <https://github.com/sjdaines/PALEOdev.jl>
you should see that your branch is there.

## Fetch and merge changes made by a collaborator

To fetch from github and merge changes made by a collaborator in your branch:

    git pull

note this combines two lower-level git operations: `git fetch` to fetch changes from github into a local remote-tracking branch, and 
`git merge` to merge those changes into the current branch.

## Optional: create a pull request on github

See the github.com docs for [Creating a pull request](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/creating-a-pull-request).

This makes it straightforward to propose and collaborate on making changes to the core PALEO code.
