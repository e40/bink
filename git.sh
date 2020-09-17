#! /bin/sh

set -eu
set -o pipefail

prog="$(basename "$0")"

function errordie {
    [ "${*-}" ] && echo "$prog: $*" 1>&2
    exit 1
}

if [ -f ".modules_$HOSTNAME" ]; then
     file="$PWD/.modules_$HOSTNAME"
elif [ -f ".modules" ]; then
     file="$PWD/.modules"
else
    errordie Cannot find a .modules file
fi

important=()
other=()
ignored=()

source "$file"

# Make sure $file defined one of the above with at least a single entry
[ ${#important[@]} -eq 0 ] &&
    [ ${#other[@]} -eq 0 ] &&
    [ ${#ignored[@]} -eq 0 ] &&
    errordie nothing defined by $file

function usage {
    [ "${*-}" ] && echo ${prog}: $*
    cat << EOF
usage: $0 [options] command

--debug       :: do not execute commands, just print them
--help        :: this help text
-a, --all     :: select all modules
--check       :: check for unknown repos
-e            :: don't stop on a non-zero exit status
-i, --ignored :: select "ignored" modules
-o, --other   :: select "other" modules
-q, --quiet   :: quiet mode -- only print something for a module if there
                 is output for COMMAND

COMMAND can include the strings MODULE and/or BRANCH, which will be
replaced with the actual repo name and/or branch in which the repo is on. 

The files $file should define one to three BASH variable arrays:

 important -- very active repos
 other	   -- inactive repos
 ignored   -- long inactive or dead repos

For example (first line is for emacs indentation):

  #! /bin/bash
  important=(. src bin)
  other=(src/pet-project src/another-pet-project)
  ignored=(src/dead-project)
EOF
    exit 1
}

m_base=xxx
m_other=
m_ignored=

ignore_errors=
check=
verbose=-v

while test $# -gt 0; do
    case $1 in
	--debug)         debug=$1 ;;
	--help)          usage ;;
	-a|--all)        m_base=$1; m_other=$1; m_ignored=$1 ;;
	--check)         check=$1 ;;
	-e)              ignore_errors=$1 ;;
	-i|--ignored)    m_base=; m_ignored=$1 ;;
	-o|--other)      m_base=; m_other=$1 ;;
	-q|--quiet)      verbose= ;;
	-*)              usage unknown argument: $1 ;;
	*)               break ;;
    esac
    shift
done

tempfile=/tmp/gitshtmp$$
rm -f $tempfile
trap "/bin/rm -f $tempfile" EXIT

if [ "$check" ]; then
    # Check for repos we don't know about

    echo important: ${#important[@]}
    echo other: ${#other[@]}
    echo ignore: ${#ignored[@]}

    # don't look in tmp/
    find . '(' -name Library -o -name tmp -o -name .cargo ')' \
	 -prune -o '(' -name .git -type d ')' -print | \
	sed -E -e 's,^\./,,g' -e 's,/\.git$,,g' > $tempfile
				  
    while read repo; do
	[ "$repo" = ".git" ] && repo=.

	[ ${#important[@]} -gt 0 ] &&
	    for r in "${important[@]}"; do
		[ "$r" = "$repo" ] && continue 2
	    done

	[ ${#other[@]} -gt 0 ] &&
	    for r in "${other[@]}"; do
		[ "$r" = "$repo" ] && continue 2
	    done

	[ ${#ignored[@]} -gt 0 ] &&
	    for r in "${ignored[@]}"; do
		[ "$r" = "$repo" ] && continue 2
	    done
	echo unknown repo: $repo
    done <<< "$(cat $tempfile)"
fi

modules=()
[ "$m_base" ]    && modules+=("${important[@]-}")
[ "$m_other" ]   && modules+=("${other[@]-}")
[ "$m_ignored" ] && modules+=("${ignored[@]-}")

# args = copy of original args from command line (with MODULE and BRANCH)
# rargs = args with MODULE and BRANCH substituted
declare -a args rargs

# In the "git.sh status" case, we don't set this below, so it must have a
# value:
args=()

subcmd=${1-}

[ "$subcmd" ] || exit 0

shift

i=1
while test $# -gt 0; do
    case $1 in
	*\ *) args[$i]="\"$1\"" ;;
	*)   args[$i]="$1" ;;
    esac
    i=$(( $i + 1 ))
    shift
done

function doit {
    l_verbose=$verbose
    if [ "$1" = "-v" ]; then
	l_verbose=yes
	shift
    fi

    if [ "$debug" ]; then
	echo would do: $*
	return
    elif [ "$l_verbose" ]; then
	echo "+" $*
    fi
    l_command=$1
    shift

    $l_command "$@" > $tempfile
    if [ "$verbose" ] || [ ! "$verbose" -a -s $tempfile ]; then
	echo ================== Directory $dir "(branch: $branch)"
	cat $tempfile
    fi
}

module_current_branch()
{
    # $1 == the directory to determine the branch of.
    local dir=${1-.}
    echo $(cd $dir && git symbolic-ref -q HEAD || echo UNKNOWN) | \
	sed 's,refs/heads/,,'
}

temp=/tmp/gitsh$$
rm -f $temp
trap "/bin/rm -f $temp" 0

back=$(pwd)
for module in "${modules[@]}"; do
    ### GLOBAL USED BY: doit
    dir=$module
    ### GLOBAL USED BY: doit
    branch=$(module_current_branch $dir)
    cd $dir

    unset rargs[@]
    nargs=${#args[@]}

    if test $nargs -gt 0; then
	i=1
	while test $nargs -gt 0; do
	    rargs[$i]=$(echo "${args[$i]}" | sed -e "s/BRANCH/$branch/g" -e "s,MODULE,$module,g")
	    nargs=$(expr $nargs - 1) || true
	    i=$(expr $i + 1)
	done
    else
# This causes a null argument to be passed, which is not good and makes
# newer git's fail with
#   fatal: empty string is not a valid pathspec.
	# rargs[0]=
	:
    fi

#HACK ALERT:
# Solution to error:
#    /usr/lib/git-core/git-sh-setup: line 183: NONGIT_OK: unbound variable
#
# The setting of the `e' and `u' shell options around the call to git rebase
# is a hack to workaround a problem exposed because "git rebase" is actually
# a shell script.  Why would this matter, you ask?  Some history: we use
# binary mode on Windows/Cygwin, which means shell scripts will have DOS EOL.
# This causes problems for Cygwin/bash unless SHELLOPTS has igncr in it,
# which is global-speak for "set -o igncr".  Because SHELLOPTS is 
# exported, doing "set -eu" causes SHELLOPTS to be side-effected and 
# subprocesses will inherit that value.  The "git rebase" shell script does
# not work when either -eu are set.  So, "set +eu" side-effects SHELLOPTS,
# as does the "set -eu" after, which is needed to make the `acl' repo scripts
# work properly.
    set +eu

    # for these git subcommands the exit status is ignored.  The logic:
    #  commit - nothing to commit is an error
    #  status - status with nothing to commit is an error
    #  grep   - nothing found is an error
    subcmdre='(commit|status|grep)'

    if doit $verbose git $subcmd "${rargs[@]}" > $temp; then
	: # OK
    elif [[ "$subcmd" =~ $subcmdre ]]; then
	: # ignore exit status from these commands
    elif test -n "$ignore_errors"; then
	echo "$0: WARNING: command return non-zero status"
    else
	echo "$0: ERROR: command return non-zero status"
	if test -s $temp; then
	    cat $temp
	fi
	exit 1
    fi

#UNDO HACK:
    set -eu

    if test -s $temp; then
	cat $temp
    fi

    cd $back
done
