#!/bin/bash
#
# * -- parser of command-line options
#
# Copyright (C) 2012-2013 yanyg
# All rights reserved
#
# Reference	: ycsh project
# License	: GPL v2 or LGPL
# Author	: yanyg
# Date		: 2012-03-27
#
# Export symbols
#	Index	Name		Type
#	1	yc_getopt	function

# prevent include repeatedly
[ "$_cf4b01321e05aab585026a219ec1f969" = "cf4b01321e05aab585026a219ec1f969" ] \
	&& return 0
_cf4b01321e05aab585026a219ec1f969=cf4b01321e05aab585026a219ec1f969

##############
# NAME
#	yc_getopt - parse command-line options
#
# SYNOPSIS
#	yc_getopt [OPTION]... [OPTSTRING]... -- [ARG]...
#
# DESCRIPTION
#
#	yc_getopt is used to parse OPTSTRINGs from ARGs. It's behavior
#	like as getopt_long and getopt in glibc
#
#	Optional OPTIONs:
#		-p, --prefix	prefix for every OPTSTRING
#		-s, --suffix	suffix for every OPTSTRING
#		-c, --callback	callback function for warning and fatal
#		-o, --continue	continue process even an error takes place
#		-v, --value	set the value for which doesn't require value
#		-x, --exec	first arg which is not an option
#	prefix and suffix and callback should be valid for shell variable.
#	callback prototype is callback warn|err <error-string>
#
#	OPTSTRINGs format is [long-option],[short-option][,:[:]].
#	optional 'long-option' for long-name, and 'short-option' for
#	short-name, relatively. Single ':' means the option must have a value,
#	and double ':' means the option need an optional value.
#	short-option: single character, in set of [a-zA-Z].
#	e.g.: user,u,: password,p,: comment,c,:: force,f opt
#	If parse success, then var name is [prefix_]<long-option>[_suffix]
#
#	ARGs is the arguments from command-line.
#
#
# RETURN VALUE
#	On success, zero is returned. Otherwise, non-zero is returned, and
#	yc_getopt_err set appropriately.
#
# EXAMPLE
#	1.
#	yc_getopt -q "user,u,:" "password,p,::" -- --user=yanyg -p123456 -e
#	Result: user=yanyg; password=123456
#	2.
#	yc_getopt --prefix arg "user,u,:" "password,p,::" -- -uyanyg -p123456
#	Result: arg_user=yanyg; arg_password=123456
#	3.
#	yc_getopt -p arg -sopt -q "user,u,:" "password,p,::" -- -u -p123456
#	Result: nothing set, and return 1 and yc_getopt_err set as
#		yc_getopt_err="option '-u' needs a value"
#

yc_getopt()
{
	local _gp_prefix _gp_suffix _gp_callback _gp_value _gp_exec
	local _gp_continue=no _gp_quiet=no

	# 1. parse options for yc_getopt
	eval $(_yc_getopt "_gp" "" "" "yes" "yes" "" ""\
		"prefix,p,:" "suffix,s,:" "callback,c,:" "quiet,q,::" \
		"continue,c,::" "value,v,:" "exec,x,:"\
		-- "$@")

	# discard yc_getopt options
	while [ -n "$1" ] && [ -z "${1##-*}" ]; do shift; done

	# 2. parse option really
	_yc_getopt "$_gp_prefix" "$_gp_suffix" "$_gp_callback" \
		"$_gp_quiet" "$_gp_continue" "$_gp_value" "$_gp_exec" "$@"
}

# _yc_getopt "[prefix]" "[suffix]" "[callback]" \
#		"[quiet]" "[continue ]" "[value]" "[exec]" [OPTSTRINGs] -- [ARGs]
_yc_getopt()
{
	local _prefix=$1 _suffix=$2 _callback=$3 _quiet=$4 _continue=$5
	local _gp_value=$6 _gp_exec=$7
	shift 7

	_prefix=${_prefix:+${_prefix}_}
	_suffix=${_suffix:+_${_suffix}}
	[ -n "$_callback" ] || _callback=_yc_getopt_callback

	# 1. parse, save all optstrings
	local lopt sopt vopt invalid opt _exec_try=""
	local lopt_array sopt_array val_array idx_array=0
	while [ $# -gt 0 ]; do
		opt=$1; shift

		[ -z "$opt" ] && continue
		[ "$opt" = "--" ] && break
		# updates long-option, short-option
		lopt=${opt%,*,*}
		[ "$lopt" = "$opt" ] && lopt=${opt%,*}
		[ "$lopt" != "$opt" ] && sopt=${opt#$lopt,}
		[ -n "$sopt" ] && vopt=${sopt#*,}
		if [ "$sopt" = ":" ] || [ "$sopt" = "::" ]; then
			vopt="$sopt"; sopt=""
		fi
		[ "$sopt" = "$vopt" ] && vopt=""
		[ -n "$sopt" ] && sopt=${sopt%,$vopt}
		if [ ${#lopt} -eq 1 ] && [ -z "$sopt" ]; then
			sopt=$lopt; lopt=""
		fi

		# check
		local valid_format="yes"
		if [ -n "$lopt" ] && [ -z "${lopt##*[!a-zA-Z0-9-_]*}" ]; then
			$_callback err "optstring '$opt' long-option error"
			valid_format=no
		fi
		if [ ${#sopt} -gt 1 ] && [ "$_continue" = "no" ] ; then
			$_callback err "optstring '$opt' short-option error"
			valid_format=no
		fi
		if [ -n "$vopt" ] && [ "$vopt" != ":" -a "$vopt" != "::" ];
		then
			$_callback err "optstring '$opt' value-option error"
			valid_format=no
		fi

		if [ "$valid_format" = "no" ]; then
			if [ -n "$_gp_exec" ]; then
				_exec_try="$_prefix$_gp_exec$_suffix='$opt'"
			fi
			continue
		elif [ -n "${opt##*[!a-zA-Z0-9]*}" ]; then
			_exec_try="$_prefix$_gp_exec$_suffix='$opt'"
		fi
		lopt_array[$idx_array]=$lopt
		sopt_array[$idx_array]=$sopt
		vopt_array[$idx_array]=$vopt
		: $((++idx_array))
	done

	# 2. parse ARGs
	local opt max_idx=$idx_array
	while [ $# -gt 0 ]; do
		opt=$1; shift 1
		[ -z "$opt" ] && continue
		local shift_cnt=0
		case "$opt" in
		--) break
		;;
		--*) _yc_getopt_lopt "$opt" "$1"
		;;
		-*) _yc_getopt_sopt "$opt" "$1"
		;;
		*)
		if [ -n "$_gp_exec" ]; then
			echo "$_prefix$_gp_exec$_suffix='$opt'"
			_gp_exec=""
		fi
		;;
		esac
		shift $shift_cnt
	done

	[ -n "$_gp_exec" ] && echo "$_exec_try"
}

# _yc_getopt_callback warn|err ...
_yc_getopt_callback()
{
	local _type=$1; shift

	if [ $# -gt 0 ] && [ "$_quiet" = "no" ]; then
		echo "<$_type>: $@" >&2
	fi

	if [ "$_type" == "err" ] && [ "$_continue" = "no" ]; then
		exit 1
	fi

	return 0
}

# _yc_getopt_lopt opt [value]
_yc_getopt_lopt()
{
	local idx real_name real_value name value opt=${1#--}

	name=${opt%%=*}
	value=${opt#*=}
	[ "$name" = "$value" ] && value=""

	real_name=$_prefix$(echo $name | tr - _)$_suffix
	real_value="$value"

	for ((idx=0; idx < max_idx; ++idx)); do
		[ "$name" = "${lopt_array[$idx]}" ] || continue

		case "${vopt_array[$idx]}" in
		":")
		[ -n "$real_value" ] || {\
			if [ -n "$2" ]; then
				real_value=$2; shift_cnt=1
			else
				$_callback warn \
					"argument '--$name' requires a value"
			fi
		}
		;;
		"::")
		:
		;;
		"")
		[ -n "$real_value" ] && $_callback warn\
			"argument '--$name' doesn't require a value"
		;;
		*)
		echo "Internal error, check code !!!" >&2
		exit 1
		;;
		esac

		[ -z "$real_value" ] && real_value=$_gp_value
		echo "$real_name='$real_value'"
		return 0
	done

	$_callback warn "unrecognized option '--$name'"
	return 1
}

# _yc_getopt_sopt opt [value]
_yc_getopt_sopt()
{
	local idx real_name real_value name value opt=${1#-}

	name=${opt%%=*}
	value=${opt#*=}
	[ "$name" = "$value" ] && value=""

	local opt_idx
	for ((opt_idx=0; opt_idx < ${#opt}; ++opt_idx)); do
		local idx cur=${opt:$opt_idx:1}
		for ((idx=0; idx < max_idx; ++idx)); do
			[ "$cur" = "${sopt_array[$idx]}" ] || continue
			case "${vopt_array[$idx]}" in
			":")
			: $((++opt_idx))
			real_value=${opt:$opt_idx}
			[ -n "$real_value" ] || \
			{
			if [ -n "$2" ]; then
				real_value=$2; shift_cnt=1
			else
				$_callback warn \
					"argument '--$name' requires a value"
			fi
			}
			;;
			"::")
			: $((++opt_idx))
			real_value=${opt:$opt_idx}
			;;
			"")
			real_value=""
			;;
			*)
			echo "Internal error, check code !!!" >&2
			exit 1
			esac

			# report
			if [ -n "${lopt_array[$idx]}" ]; then
				real_name=$_prefix${lopt_array[$idx]}$_suffix
			else
				real_name=$_prefix$cur$_suffix
			fi

			[ -z "$real_value" ] && real_value=$_gp_value
			echo "$real_name='$real_value'"
			[ -n "$real_value" ] && opt_idx=${#opt}
			break
		done

		[ "$idx" -lt "$max_idx" ] || \
			$_callback warn "unrecognized option '-$name'"
	done
}
