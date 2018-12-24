# BASH prompt hacking

It alters `PS1` to change the way the prompt is printed.

This BASH script does these things:

* adds `@` or `-` to the beginning of the prompt to indicate whether
  the SSH agent is operational and has at least one identity (`@`), or
  a `-` if it is operational and has no identities added.  This
  feature is dependent on using [bash_sshagent](bash_sshagent.md).  If
  that code is not loaded, then this feature is simply not available.

* If the current directory is in a `git` repository, then add the git
  branch to the prompt.

* Sets up the Allegro Common Lisp build environment, when `cd`ing into
  a binary directory for a given platform.  It redefines `cd`, `pushd`
  and `popd` to do this, calling the built-in versions of each.  This
  feature is obviously only useful to developers of ACL.
