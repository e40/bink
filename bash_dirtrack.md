# BASH directory tracking

Redefine `cd`, `pushd` and `popd` so that:

* change directory targets are localized,
* if a change directory target is an ACL binary directory, then
  initialize it for building ACL.

Localized directories are those without NFS adornments (e.g.,
`/net/...` or `/fi/...`).

To use it, simply add this to the non-interactive portion of your
`$HOME/.bashrc`:

    source $HOME/bink/bash_dirtrack
