
Example `$HOME/.sshwraprc`:

```
#! /bin/bash
# This script defines these variable:
#   __sshwrap_config_files
#   __sshwraprc_force_update
#
# NOTE: this file is source'd so use return not exit to terminate
#       processing.

# Because we don't want the calculations here to happen for every
# ssh/scp invocation, we cache the result and use that if it exists
# and we're not on my laptop.

__sshwraprc_cache_config="$HOME/.sshwraprc.cached_config"
__sshwraprc_cache_myip="$HOME/.sshwraprc.cached_ip"
__sshwraprc_cache_extip="$HOME/.sshwraprc.cached_extip"

# if non-null then force an update to ~/.ssh/config
__sshwraprc_force_update=

myip=$(curl -4 -s http://icanhazip.com) || errordie could not determine IP

if [ ! "$myip" ] || 
   [ ! -f "${__sshwraprc_cache_myip}" ] ||
   [ "$myip" != "$(cat "${__sshwraprc_cache_myip}")" ]
then
    # either the first time through this code OR
    # laptop moved from one zone to another
    echo $myip > "${__sshwraprc_cache_myip}"
    __sshwraprc_force_update=nonnull
fi

extip=$(my-external-ip)

if [ ! -f "${__sshwraprc_cache_extip}" ] ||
   [ "$extip" != "$(cat "${__sshwraprc_cache_extip}")" ]
then
    # our external IP changed, so force update
    echo $extip > "${__sshwraprc_cache_extip}"
    __sshwraprc_force_update=nonnull
fi

__sshwrap_config_files=( $HOME/.ssh/config_top )

if [ $myip = $extip ]; then
    __sshwrap_config_files+=( $HOME/.ssh/config_int )
else
    __sshwrap_config_files+=( $HOME/.ssh/config_ext )
fi

cat <<EOF > "${__sshwraprc_cache_config}"
__sshwrap_config_files=( ${__sshwrap_config_files[@]} )
EOF
```
The script `my-external-ip` does this
```
nslookup host.mydomain.com dns1.registrar-servers.com
```
I use `dns1.registrar-servers.com` since I use namecheap.com as my
domain registrar, and that's one of their two nameservers.
