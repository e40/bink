
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
__sshwraprc_cache_ip="$HOME/.sshwraprc.cached_ip"

# if non-zero then force an update to ~/.ssh/config
__sshwraprc_force_update=

if [ "$(hostname -s)" = "gazorpazorp" ]; then
    # always check
    :
elif [ -f "${__sshwraprc_cache_config}" ]; then
    source "${__sshwraprc_cache_config}"

    if [ ${#__sshwrap_config_files[@]} -gt 0 ]; then
        return 0
    fi
    # fall through...
fi

###############################################################################

ip=$(curl -4 -s http://icanhazip.com) || errordie could not determine IP

if [ ! "$ip" ] || 
   [ ! -f "${__sshwraprc_cache_ip}" ] ||
   [ "$ip" != "$(cat "${__sshwraprc_cache_ip}")" ]
then
    # either the first time through this code OR
    # laptop moved from one zone to another
    __sshwraprc_force_update=nonnull
fi

__sshwrap_config_files=( $HOME/.ssh/config_top )

# 73.241.139.91 is my Comcast dynamic IP that never changes.
if [[ $ip =~ ^73\.241\.139\.91 ]]; then
    __sshwrap_config_files+=( $HOME/.ssh/config_int )
else
    __sshwrap_config_files+=( $HOME/.ssh/config_ext )
fi

cat <<EOF > "${__sshwraprc_cache_config}"
__sshwrap_config_files=( ${__sshwrap_config_files[@]} )
EOF

```
