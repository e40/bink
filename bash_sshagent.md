# Automatic SSH agent handling

The code in bash_sshagent provides BASH support for running a single
SSH agent on the machines you sit at, and using that agent on the
network of machines that you use.  The file is intended to be sourced by
$HOME/.bashrc.

It is used daily on macOS, Linux and Windows (via Cygwin).

## Configuration

For the purposes of this document, it is assumed that `$HOME/bink` is
a clone of the git repository.

### .bashrc

    # Return true this machine should run an SSH agent, false otherwise.
    # In other words, do I sit at the machine? Then return true.
    function __my_ssh_run_agent_p {
        [[ $HOSTNAME =~ (gazorpazorp|mack2) ]] && return 0
        return 1
    }
    __my_ssh_default_identity="$HOME/.ssh/id_rsa $HOME/.ssh/id_rsa_franz"
    __my_ssh_default_identity_md5="xx:xx:xx:xx:xx:xx yy:yy:yy:yy:yy:yy"

    source $HOME/bink/bash_sshagent

If you use `bink/bash_prompt`, then make sure it is `source`d after
`bash_sshagent`, and in the interactive portion of `$HOME/.bashrc`
(see below).

If you have interactive and non-interactive parts of your BASH
initialization, the above code should be in the non-interactive
portion.  That is, `ssh machine ...` should execute it.  Typically,
this is done via something like this:

    ...code always executed goes here...

    # If not running interactively, don't do anything else
    [ -z "$PS1" ] && return

    ...code only executed for interactive shells goes here...

All the functions and variables in `bash_sshagent` are prefixed with
`__my_ssh_` to minimize the chance of collisions with code written by
others.

### SSH configuration

For SSH agent forwarding to work, you need to use the appropriate
`ssh` command line arguments (`-A` or `-o ForwardAgent=yes`) or
`$HOME/.ssh/config` configuration file options using the
`ForwardAgent` directive.

## Security considerations 

Having SSH forward agent authentication can represent a security
problem.  Be aware of where you forward connections and use
`ForwardAgent` in host-specific configuration in `$HOME/.ssh/config`.

You might want to have the default by `ForwardAgent yes`, but then in
specific hosts definitions do `ForwardAgent no`.  Or, you can default
it to off and turn it on for a list of hosts, like this:

    ForwardAgent no

    Host box tines relay mack2
      ForwardAgent yes
