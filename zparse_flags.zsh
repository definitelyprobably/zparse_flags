#!/bin/zsh
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#                                                                           #
#   zparse_flags                                                            #
#                                                                           #
#   Version:      0.0.0                                                     #
#   Author:       Karta Kooner                                              #
#   Contact:      ksa.kooner@gmail.com                                      #
#   Copyright:    GNU GPL v3+                                               #
#                                                                           #
#   This file provides zsh shell functions for parsing command-line         #
#   inputs. Simply source this file into your shell script to use the       #
#   functions.                                                              #
#                                                                           #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


zparse_flags_version=0.0.0


zparse_flags_quote_left=${zparse_flags_quote_left-"\xe2\x80\x98"}
zparse_flags_quote_right=${zparse_flags_quote_right-"\xe2\x80\x99"}

#
# pfpie x            –> "...internal error: x"
# pfpie x y          –> "...internal error: x: y"
# pfpie x y z        –> "...internal error: x: arg y: z"
# pfpie x y z w      –> "...internal error: x: arg y: flag variable z: w"
# pfpie x y z w u... –> "...internal error: w x y z u..."
function zparse_flags_print_internal_error() {
	[[ $zparse_flags_internal_error_quiet == 1 ]] && return

	if (($# == 1)) ; then
		echo - "${zparse_flags_preamble}${zparse_flags_error_start}${zparse_flags_internal_error_start}zparse_flags: internal error: $1${zparse_flags_internal_error_end}${zparse_flags_error_end}${zparse_flags_postscript}" >&2
	elif (($# == 2)) ; then
		echo - "${zparse_flags_preamble}${zparse_flags_error_start}${zparse_flags_internal_error_start}zparse_flags: internal error: $1: $2${zparse_flags_internal_error_end}${zparse_flags_error_end}${zparse_flags_postscript}" >&2
	elif (($# == 3)) ; then
		echo - "${zparse_flags_preamble}${zparse_flags_error_start}${zparse_flags_internal_error_start}zparse_flags: internal error: $1: arg $2: $3${zparse_flags_internal_error_end}${zparse_flags_error_end}${zparse_flags_postscript}" >&2
	elif (($# == 4)) ; then
		echo - "${zparse_flags_preamble}${zparse_flags_error_start}${zparse_flags_internal_error_start}zparse_flags: internal error: $1: arg $2: flag variable ${zparse_flags_quote_left}$3${zparse_flags_quote_right}: $4${zparse_flags_internal_error_end}${zparse_flags_error_end}${zparse_flags_postscript}" >&2
	else
		echo - "${zparse_flags_preamble}${zparse_flags_error_start}${zparse_flags_internal_error_start}zparse_flags: internal error: ${@}${zparse_flags_internal_error_end}${zparse_flags_error_end}${zparse_flags_postscript}" >&2
		return 1
	fi
}

#
# pfpe x            –> "error: x"
# pfpe x y          –> "error: arg x: y"
# pfpe x 0 z        –> "error: arg x: z"
# pfpe x 1 z        –> "error: arg x, flag 1: z"
# pfpe x y z        –> "error: arg x: z"
# pfpe w x y z...   –> "error: w x y z..."
#
function zparse_flags_print_error() {
	if (($# == 1)) ; then
		echo - "${zparse_flags_preamble}${zparse_flags_error_start}error: ${1}${zparse_flags_error_end}${zparse_flags_postscript}" >&2
	elif (($# == 2)) ; then
		echo - "${zparse_flags_preamble}${zparse_flags_error_start}error: arg ${1}: ${2}${zparse_flags_error_end}${zparse_flags_postscript}" >&2
	elif (($# == 3)) ; then
		if (($2 > 1)) ; then
			echo - "${zparse_flags_preamble}${zparse_flags_error_start}error: arg ${1}, flag ${2}: ${3}${zparse_flags_error_end}${zparse_flags_postscript}" >&2
		else
			echo - "${zparse_flags_preamble}${zparse_flags_error_start}error: arg ${1}: ${3}${zparse_flags_error_end}${zparse_flags_postscript}" >&2
		fi
	else
		echo - "${zparse_flags_preamble}${zparse_flags_error_start}error: ${@}${zparse_flags_error_end}${zparse_flags_postscript}" >&2
		return 1
	fi
}

# FUNCTION:  zparse_flags_usage_name {flag_name} [value]
#
# print the varible name that has the usage data for the flag 'flag_name'.
# Optionally, if given 'value' then print that position of the usage data
# variable. E.g.:
#
#   flag_B=(B --bare)
#   zparse_flags flag_B --- --bare
#   zparse_flags_usage_name flag_B
#      # -> returns "flag_B_usage"
#   zparse_flags_usage_name flag_B 1
#      # -> returns "$flag_B_usage[1]" -> "1,--bare"
#
# Note that if 'value' is:
#     -   - (single dash) then treat it as if it was -1, and
#           echo $flag_B_usage[-1]
#     0   - treat as if no 'value' was given and echo $flag_B_usage
#     N   - (postitive integer) then echo $flag_B_usage[N]
#     -N  - (negative integer) then echo $flag_B_usage[-N]
#     *   - treat as an error and return 2
#
# prints: <nothing> or the usage variable name
# returns: 0 if the name is printed
#          1 if 'flag_name' has no usage variable associated with it
#          2 if not enough flag arguments have been given or they are
#            malformed.
function zparse_flags_usage_name () {
	if [[ -z $1 ]] ; then
		zparse_flags_print_internal_error $0 1 "require a flag specification."
		return 2
	fi
	local name=${zparse_flags_usage_name_map[$1]}
	if [[ -z $name ]] ; then
		return 1
	fi

	if [[ -z $2 ]] ; then
		echo - $name
	else
		integer at
		if [[ $2 == "-" ]] ; then
			at=-1
		else
			at=$2
			if [[ $at != $2 ]] ; then
				zparse_flags_print_internal_error $0 2 "must be a number: ${zparse_flags_quote_left}$2${zparse_flags_quote_right}"
				return 2
			fi
		fi
		if (( at == 0 )); then
			# zsh indices run [1-N], interpret 0 to mean just act like
			# no 'value' argument was given,
			echo - $name
			return
		fi

		local name2=${${(P)name}[at]}
		if [[ -z $name2 ]] ; then
			return 1
		fi
		echo - $name2
	fi
}

# FUNCTION:  zparse_flags_inputs_name {flag_name} [value]
#
# print the varible name that has the inputs data for the flag 'flag_name'.
# Optionally, if given 'value' then print that position of the inputs data
# variable. E.g.:
#
#   flag_O=(O -o)
#   flag_M=(M -m)
#
#   zparse_flags flag_O --- -oA
#   zparse_flags_inputs_name flag_O
#      # -> returns "flag_O_inputs"
#   zparse_flags_inputs_name flag_O 1
#      # -> returns "$flag_O_inputs[$flag_O_usage[1]]" -> ":<A"
#
#   zparse_flags flag_M --- -m A
#   zparse_flags_inputs_name flag_M 1
#      # -> returns "$flag_M_inputs[$flag_M_usage[1]]" -> ":>A"
#
#   zparse_flags flag_O --- -o
#   zparse_flags_inputs_name flag_O 1
#      # -> returns "$flag_O_inputs[$flag_M_usage[1]]" -> "_"
#
# Note that if 'value' is:
#     -   - (single dash) then treat it as if it was -1, and
#           echo $flag_X_inputs[$flag_X_usage[-1]]
#     0   - treat as if no 'value' was given and echo $flag_X_usage
#     N   - (postitive integer) then echo $flag_X_inputs[$flag_X_usage[N]]
#     -N  - (negative integer) then echo $flag_X_inputs[$flag_X_usage[-N]]
#     x   - (anything else) echo $flag_X_inputs[x]. If the key value x is
#           not in the associative array flag_X_inputs, then nothing will
#           be printed and the function will return 1
#
# prints: <nothing> or the inputs variable name
# returns: 0 if the name is printed
#          1 if 'flag_name' has no inputs variable associated with it
#          2 if not enough flag arguments have been given
function zparse_flags_inputs_name () {
	if [[ -z $1 ]] ; then
		zparse_flags_print_internal_error $0 1 "require a flag specification."
		return 2
	fi
	local name=${zparse_flags_inputs_name_map[$1]}
	if [[ -z $name ]] ; then
		return 1
	fi

	if [[ -z $2 ]] ; then
		echo - $name
	else
		local key
		if [[ $2 == "-" ]] ; then
			key=$(zparse_flags_usage_name $1 $2)
		else
			integer at=$2
			if [[ $at == $2 ]] ; then
				# if given a number, then call zparse_flags_usage_name to
				# get the key...
				key=$(zparse_flags_usage_name $1 $2)
			else
				# ...otherwise we have they key already
				key=$2
			fi
		fi

		typeset -A assoc=(${(Pkv)name})
		local name2=${assoc[$key]}
		if [[ -z $name2 ]] ; then
			return 1
		fi
		echo - $name2
	fi
}

# FUNCTION:  zparse_flags_has_flag {flag_name}
#
# prints: <nothing>.
# returns: 0 if $1 is not empty.
#          1 if $1 it is empty.
#          2 if not enough flag arguments have been given.
function zparse_flags_has_flag () {
	if [[ -z $1 ]] ; then
		zparse_flags_print_internal_error $0 1 "require a flag specification."
		return 2
	fi
	[[ -n ${(P)$(zparse_flags_usage_name $1)} ]]
}

# FUNCTION:  zparse_flags_get_instances {flag_name}
#
# prints: the array size of $1 (or the size of the string if not an array).
# returns: 2 if not enough inputs have been given.
#          0 otherwise.
function zparse_flags_get_instances () {
	if [[ -z $1 ]] ; then
		zparse_flags_print_internal_error $0 1 "require a flag specification."
		return 2
	fi
	echo - ${(P)#$(zparse_flags_usage_name $1)}
}

# FUNCTION:  zparse_flags_is_input_internal {flag_name} [instance]
#
# when a flag input is given on the same argument input like so:
#   -ofile
#   --output=file
# then the input is called "internal"; otherwise, when given as:
#   -o file
#   --output file
# it is called "external".
# This functions returns whether the flag input has been given internally.
# The flag to test for can be specified with 'instance', or else if it is
# empty or set to "-", then take the last occurrence of the flag.
#
# prints: <nothing>
# returns: 0 if input is internal.
#          1 if the input is external.
#          2 if flag has no input given.
#          3 if not enough flag arguments have been given or any arguments
#            are malformed.
function zparse_flags_is_input_internal () {
	setopt localoptions
	setopt extendedglob
	if [[ -z $1 ]] ; then
		zparse_flags_print_internal_error $0 1 "require a flag specification."
		return 3
	fi

	if [[ -z $2 ]] ; then
		local input=$(zparse_flags_inputs_name $1 -1)
	else
		local input=$(zparse_flags_inputs_name $1 $2)
	fi
	# flagval could have any of the forms:
	#  1. 4            : print nothing, return 3
	#  2. 4,-f         : print nothing, return 3
	#  3. 4,-f:>input  : print nothing, return 1
	#  4. 4,-f:<input  : print nothing, return 0
	#  5. 4,-f:|input  : print nothing, return 2
	#
	if [[ -z $input || $input == _ ]] ; then
		return 2
	elif [[ $input[1,2] == ":<" ]] ; then
		return 0
	elif [[ $input[1,2] == ":>" ]] ; then
		return 1
	else
		zparse_flags_print_internal_error $0 "unexpected response: ${zparse_flags_quote_left}${input}${zparse_flags_quote_right}"
		return 3
	fi
}

# FUNCTION:  zparse_flags_is_input_external {flag_name} [instance]
#
# when a flag input is given on the same argument input like so:
#   -ofile
#   --output=file
# then the input is called "internal"; otherwise, when given as:
#   -o file
#   --output file
# it is called "external".
# This functions returns whether the flag input has been given externally.
# The flag to test for can be specified with 'instance', or else if it is
# empty or set to "-", then take the last occurrence of the flag.
#
# prints: <nothing>
# returns: 0 if input is external.
#          1 if the input is internal.
#          2 if flag has no input given.
#          3 if not enough flag arguments have been given or any arguments
#            are malformed.
function zparse_flags_is_input_external () {
	setopt localoptions
	setopt extendedglob
	if [[ -z $1 ]] ; then
		zparse_flags_print_internal_error $0 1 "require a flag specification."
		return 3
	fi

	if [[ -z $2 ]] ; then
		local input=$(zparse_flags_inputs_name $1 -1)
	else
		local input=$(zparse_flags_inputs_name $1 $2)
	fi
	# flagval could have any of the forms:
	#  1. 4            : print nothing, return 3
	#  2. 4,-f         : print nothing, return 3
	#  3. 4,-f:>input  : print nothing, return 1
	#  4. 4,-f:<input  : print nothing, return 0
	#  5. 4,-f:|input  : print nothing, return 2
	#
	if [[ -z $input || $input == _ ]] ; then
		return 2
	elif [[ $input[1,2] == ":>" ]] ; then
		return 0
	elif [[ $input[1,2] == ":<" ]] ; then
		return 1
	else
		zparse_flags_print_internal_error $0 "unexpected response: ${zparse_flags_quote_left}${input}${zparse_flags_quote_right}"
		return 3
	fi
}


# FUNCTION:  zparse_flags_get_input {flag_name} [instance]
#
# if 'instance' is not given or equal to the string "-", then take the last
# occurrence of flag, otherwise take the flag instance number given.
#
# prints: the input to a flag (part following '[0-9.]*,flag:[<,>]') if extant,
#         or else <nothing> (so, it returns something or nothing, not even a
#         lone newline).
# returns: 0 if the input of flag_name is not empty.
#          1 if the input of flag_name is empty.
#          2 if not enough flag arguments have been given or any arguments
#            are malformed.
#
# example:
#  flag1="5,--flag"
#  flag2="5,--flag:>value"
#
#  zparse_flags_get_input flag1
#     output: <nothing>
#     returns: 1
#
#  zparse_flags_get_input flag2
#     output: "value"
#     returns: 0
#
# This shell function can be used like this:
#   if var=$(zparse_flags_get_input flag...); then
#       # flag has input, now stored in the shell parameter "var".
#   else
#       # flag has no input.
#   fi
#
# This shell function can be used by both option and mandatory flags, where
# for the latter the function will always return an input.
function zparse_flags_get_input () {
	setopt localoptions
	setopt extendedglob
	if [[ -z $1 ]] ; then
		zparse_flags_print_internal_error $0 1 "require a flag specification."
		return 2
	fi

	if [[ -z $2 ]] ; then
		local input=$(zparse_flags_inputs_name $1 -1)
	else
		local input=$(zparse_flags_inputs_name $1 $2)
	fi
	if [[ -z $input || $input == _ ]] ; then
		return 1
	fi
	echo - $input[3,$]
	:
}

# FUNCTION:  zparse_flags_get_all_inputs {flag_name} {into_var} \
#                                        [[from=]NUM1] [[to=]NUM2]
#
# create and fill an array variable called 'into_var' with all inputs
# recorded in the flag 'flag_name'. The range of inputs can be changed with
# extra function inputs: the starting range can be set with a number or
# optionally in the format 'from=<NUM>'. Similarly, the ending range can be
# set with a number or optionally in the format 'to=<NUM>'. If either input
# is empty or equal to the value '-' then the default values are used, which
# is for the whole range of inputs to be captured. Note: the starting range
# has value '1' and not '0'.
#
# The 'into_var' variable name cannot begin 'zparse_flags_', in order that
# it not conflict with internal variables; and this function will overwrite
# 'into_var' if it is not empty.
#
# prints: <nothing>
# returns: 0 if the function succeeds and the variable is filled
#          1 if the 'flag_name' is empty (and so there are no inputs) or
#            there are no actual inputs to fill.
#          2 if not enough inputs are given or the range inputs are not
#            valid inputs.
function zparse_flags_get_all_inputs () {
	if [[ -z $1 ]] ; then
		zparse_flags_print_internal_error $0 1 "require a flag specification."
		return 2
	elif [[ -z $2 ]] ; then
		zparse_flags_print_internal_error $0 2 "require a parameter name."
		return 2
	elif [[ ${2[1,13]} == zparse_flags_ ]] ; then
		zparse_flags_print_internal_error $0 2 "parameter name cannot begin ${zparse_flags_quote_left}zparse_flags_${zparse_flags_quote_right}."
		return 2
	fi

	if ! zparse_flags_has_flag $1 ; then
		return 1
	fi
	setopt localoptions
	setopt extendedglob

	if [[ -z $3 || $3 == - ]] ; then
		integer zparse_flags_from=1
	elif [[ -z ${3##zparse_flags_from=[0-9]##} || -z ${3##[0-9]##} ]] ; then
		integer zparse_flags_from=$3
		((zparse_flags_from != $3)) && return 2
	else
		zparse_flags_print_internal_error $0 3 "must be a number: ${zparse_flags_quote_left}$3${zparse_flags_quote_right}"
		return 2
	fi
	if [[ -z $4 || $4 == - ]] ; then
		integer zparse_flags_to=$(zparse_flags_get_instances $1)
	elif [[ -z ${4##zparse_flags_to=[0-9]##} || -z ${4##[0-9]##} ]] ; then
		integer zparse_flags_to=$4
		if ((zparse_flags_to != $4)) ; then
			zparse_flags_print_internal_error $0 4 "must be a number: ${zparse_flags_quote_left}$4${zparse_flags_quote_right}"
			return 2
		fi
	else
		zparse_flags_print_internal_error $0 4 "must be a number: ${zparse_flags_quote_left}$4${zparse_flags_quote_right}"
		return 2
	fi
	if ((zparse_flags_to == 0)) ; then
		zparse_flags_print_internal_error $0 4 "${zparse_flags_quote_left}to${zparse_flags_quote_right} argument cannot be zero."
		return 2
	elif ((zparse_flags_from == 0)) ; then
		zparse_flags_print_internal_error $0 3 "${zparse_flags_quote_left}from${zparse_flags_quote_right} argument cannot be zero."
		return 2
	elif ((zparse_flags_from > zparse_flags_to)) ; then
		zparse_flags_print_internal_error $0 "${zparse_flags_quote_left}from${zparse_flags_quote_right} value (${zparse_flags_quote_left}$3${zparse_flags_quote_right}) larger than ${zparse_flags_quote_left}to${zparse_flags_quote_right} value (${zparse_flags_quote_left}$4${zparse_flags_quote_right})."
		return 2
	fi

	integer zparse_flags_i
	local zparse_flags_j
	local -a zparse_flags_k
	for ((zparse_flags_i=$zparse_flags_from; zparse_flags_i<=$zparse_flags_to; zparse_flags_i++))
	do
		zparse_flags_j="$(zparse_flags_get_input $1 $zparse_flags_i)" \
			&& zparse_flags_k+=( $zparse_flags_j )
	done
	if [[ -z $zparse_flags_k ]] ; then
		return 1
	fi
	set -A $2 $zparse_flags_k
	:
}

# FUNCTION:  zparse_flags_get_number {flag_name} [instance]
#
# if 'instance' is not given or equal to the string "-", then take the last
# occurrence of flag, otherwise take the flag instance number given.
#
# prints: the argument position of a flag (part that is '[0-9],..:[<,>]...'),
#         which should always be present. The function will print <nothing>
#         if an error occurs.
# returns: 0 if the argument number of $1 is not empty.
#          1 if the argument number of $1 is empty.
#          2 if not enough flag arguments have been given.
function zparse_flags_get_number () {
	setopt localoptions
	setopt extendedglob
	if [[ -z $1 ]] ; then
		zparse_flags_print_internal_error $0 1 "require a flag specification."
		return 2
	fi
	if [[ -z $2 ]] ; then
		local flagval=$(zparse_flags_usage_name $1 -1)
	else
		local flagval=$(zparse_flags_usage_name $1 $2)
	fi
	local num=${(M)flagval##[0-9]##}
	if [[ -z $num ]] ; then
		return 1
	fi
	echo - $num
	:
}

# FUNCTION:  zparse_flags_get_full_number {flag_name} [instance]
#
# if 'instance' is not given or equal to the string "-", then take the last
# occurrence of flag, otherwise take the flag instance number given.
#
# prints: the full argument position of a flag (part that is
# 		  '[0-9.],..:[<,>]...'), which should always be present. The function
# 		  will print <nothing> if an error occurs.
# returns: 0 if the argument number of $1 is not empty.
#          1 if the argument number of $1 is empty.
#          2 if not enough flag arguments have been given.
function zparse_flags_get_full_number () {
	setopt localoptions
	setopt extendedglob
	if [[ -z $1 ]] ; then
		zparse_flags_print_internal_error $0 1 "require a flag specification."
		return 2
	fi
	if [[ -z $2 ]] ; then
		local flagval=$(zparse_flags_usage_name $1 -1)
	else
		local flagval=$(zparse_flags_usage_name $1 $2)
	fi
	local num=${(M)flagval##[0-9.]##}
	if [[ -z $num ]] ; then
		return 1
	fi
	echo - $num
	:
}

# FUNCTION:  zparse_flags_get_chain_number {flag_name} [instance]
#
# if 'instance' is not given or equal to the string "-", then take the last
# occurrence of flag, otherwise take the flag instance number given.
#
# prints: the chain position of a flag (part that is '...\.[0-9],..:[<,>]...'),
#         which is not necessarily always present. The function will print
#         <nothing> if an error occurs. A number is only printed if the flag
#         is in a chain, otherwise it will print nothing and return 1
# returns: 0 if the argument number of $1 is not empty.
#          1 if the argument number of $1 is empty.
#          2 if not enough flag arguments have been given.
function zparse_flags_get_chain_number () {
	setopt localoptions
	setopt extendedglob
	if [[ -z $1 ]] ; then
		zparse_flags_print_internal_error $0 1 "require a flag specification."
		return 2
	fi
	if [[ -z $2 ]] ; then
		local flagval=$(zparse_flags_usage_name $1 -1)
	else
		local flagval=$(zparse_flags_usage_name $1 $2)
	fi
	local num=${${(M)${flagval%%,*}%.*}[2,$]}
	if [[ -z $num ]] ; then
		return 1
	fi
	echo - $num
	:
}

# FUNCTION:  zparse_flags_get_flag {flag_name} [instance]
#
# if 'instance' is not given or equal to the string "-", then take the last
# occurrence of flag, otherwise take the flag instance number given.
#
# prints: the actual flag given (part given as: '...,--flag:[<,>]...'),
#         which should always be present. The function will print <nothing>
#         if an error occurs.
# returns: 0 if flag_name has an associated flag.
#          1 if flag_name has no associated flag.
#          2 if not enough flag arguments have been given or they are
#            malformed.
function zparse_flags_get_flag () {
	setopt localoptions
	setopt extendedglob
	if [[ -z $1 ]] ; then
		zparse_flags_print_internal_error $0 1 "require a flag specification."
		return 2
	fi
	if [[ -z $2 ]] ; then
		local flagval=$(zparse_flags_usage_name $1 -1)
	else
		local flagval=$(zparse_flags_usage_name $1 $2)
	fi
	# flagval could have any of the forms:
	#  1. 4            : print nothing, return 1
	#  2. 4,-f         : print "-f", return 0
	#  3. 4,-f:>input  : print "-f", return 0
	#
	# We will search for ${(M)flagval##[0-9.]##,}. This will only return a
	# non-empty string for scenarios 2 and 3, whilst it will return nothing
	# for scenario 1. In this latter case, we have nothing more to do than
	# return 1:
	if [[ -z ${(M)flagval##[0-9.]##,} ]] ; then
		return 1
	fi
	# Next, we need to extract the flag from scenarios 2 and 3. First let's
	# remove the position string:
	echo - ${flagval##[0-9.]##,}
}

# FUNCTION:  zparse_flags_is_IAU_S {flag_name} [instance]
#
# if 'flag_name' is an IAU flag, and if the last input (or else 'instance'
# if it is present) is captured only because it occurred after an S flag,
# then return 0.
#
# if 'instance' is not given or equal to the string "-", then take the last
# occurrence of flag, otherwise take the flag instance number given.
#
# prints: nothing
# returns: 0 if the IAU flag input is _[IAU]S
#          1 if the IAU flag input is _[IAU]
#          2 if not enough flag arguments have been given, or any arguments
#            are malformed, or if flag_name has no associated flag or is not
#            an IAU flag.
#
function zparse_flags_is_IAU_S() {
	if [[ -z $1 ]] ; then
		zparse_flags_print_internal_error $0 1 "require a flag specification."
		return 2
	fi

	local flagno=${2-"-"}
	local flagval
	if ! flagval=$(zparse_flags_get_flag $1 $flagno) ; then
		zparse_flags_print_internal_error $0 "no flag ${zparse_flags_quote_left}$1${zparse_flags_quote_right} with instance ${zparse_flags_quote_left}$flagno${zparse_flags_quote_right}."
		return 2
	else
		if [[ $flagval[1] != _ ]] ; then
			zparse_flags_print_internal_error $0 "flag ${zparse_flags_quote_left}$1${zparse_flags_quote_right} not an IAU flag."
			return 2
		elif [[ $flagval[-1] != S ]] ; then
			return 1
		else
			return 0
		fi
	fi
}

# FUNCTION:  zparse_flags_is_input_after {flag1} {inst1} {flag2} {inst2}
#
# if 'inst1' or 'inst2' is not given or equal to the string "-", then take
# the last occurrence of flag, otherwise take the flag instance number given.
#
# prints: nothing
# returns: 0 if flag2 inst2 occurs after flag1 inst1.
#          1 if flag2 inst2 occurs at or before flag1 inst1.
#          2 if not enough flag arguments have been given, or any arguments
#            are malformed.
#
function zparse_flags_is_input_after() {
	setopt localoptions
	setopt extendedglob
	if [[ -z $1 ]] ; then
		zparse_flags_print_internal_error $0 1 "require a flag specification."
		return 2
	elif [[ -z $3 ]] ; then
		zparse_flags_print_internal_error $0 3 "require a flag specification."
		return 2
	fi

	local pos1
	if ! pos1=$(zparse_flags_get_full_number $1 $2) ; then
		zparse_flags_print_internal_error $0 "flag ${zparse_flags_quote_left}$1${zparse_flags_quote_right} at instance ${zparse_flags_quote_left}$2${zparse_flags_quote_right}; could not get a position."
		return 2
	fi

	local pos2
	if ! pos2=$(zparse_flags_get_full_number $3 $4) ; then
		zparse_flags_print_internal_error $0 "flag ${zparse_flags_quote_left}$3${zparse_flags_quote_right} at instance ${zparse_flags_quote_left}$4${zparse_flags_quote_right}; could not get a position."
		return 2
	fi

	# N.B: The following IS correct!
	return $(( pos2 <= pos1 ))
}

# FUNCTION:  zparse_flags_add_flag_after {flagname} {pos} {flag} [[<,>]input]
#
# add a flag instance to 'flagname'. The format of flag instances in this
# version of parse-flags is:
#   (command-line-position,flag-name[:{<,>}input] ...)
# where 'input' is optional.
# For example:
#   ./binary --help --output=stdout -h
# would have flag instances:
#   help_flag: (1,--help 3,-h)
#   output_flag: (2,--output:<stdout)
#
# To replicate this behaviour, we can issue:
#   zparse_flags_add_flag_after  help_flag 1 --help
#     -> (1,--help)
#   zparse_flags_add_flag_after  help_flag 2 --opt >input
#     -> (2,--opt:>input)
#   zparse_flags_add_flag_after  help_flag 3 --opt <input
#     -> (3,--opt:<input)
#
# Note that 'input' may optionally begin with '<' or '>' to indicate that
# the input was entered on the same argument input or the next one,
# respectively. If ommited, then the function will assume it was given on the
# next input; that is, as if a '>' was given.
#
# Note: this function does not attempt to order the flag instances by
#       position. It will insert whatever is specified at the end of the
#       flag instances array. To add to the beginning of the list, use the
#       function 'zparse_flags_add_flag_before'. If you want to add a flag
#       sorted into position, use 'zparse_flags_add_flag'.
#
# prints: <nothing>
# returns: 0 if completed successfully.
#          2 if not enough inputs given (flagname, pos and flag are all
#            mandatory).
function zparse_flags_add_flag_after () {
	if [[ -z $1 ]] ; then
		zparse_flags_print_internal_error $0 1 "require a flag specification."
		return 2
	elif [[ -z $2 ]] ; then
		zparse_flags_print_internal_error $0 2 "require position to add flag."
		return 2
	elif [[ -z $3 ]] ; then
		zparse_flags_print_internal_error $0 3 "require flag name to add."
		return 2
	fi
	eval $(zparse_flags_usage_name $1)+=\(\$2,\$3\)
	if [[ -n $4 ]] ; then
		if [[ ${4[1]} == "<" || ${4[1]} == ">" ]] ; then
			eval $(zparse_flags_inputs_name $1)\[\$2,\$3\]=\":\$4\"
		else
			eval $(zparse_flags_inputs_name $1)\[\$2,\$3\]=\":\>\$4\"
		fi
	else
		eval $(zparse_flags_inputs_name $1)\[\$2,\$3\]=\"_\"
	fi
	:
}

# FUNCTION:  zparse_flags_add_flag_before {flagname} {pos} {flag} [[<,>]input]
#
# add a flag instance to 'flagname'. The format of flag instances in this
# version of parse-flags is:
#   (command-line-position,flag-name[:{<,>}input] ...)
# where 'input' is optional.
# For example:
#   ./binary --help --output=stdout -h
# would have flag instances:
#   help_flag: (1,--help 3,-h)
#   output_flag: (2,--output:<stdout)
#
# To replicate this behaviour, we can issue:
#   zparse_flags_add_flag  help_flag 1 --help
#     -> (1,--help)
#   zparse_flags_add_flag  help_flag 2 --opt >input
#     -> (2,--opt:>input)
#   zparse_flags_add_flag  help_flag 3 --opt <input
#     -> (3,--opt:<input)
#
# Note that 'input' may optionally begin with '<' or '>' to indicate that
# the input was entered on the same argument input or the next one,
# respectively. If ommited, then the function will assume it was given on the
# next input; that is, as if a '>' was given.
#
# Note: this function does not attempt to order the flag instances by
#       position. It will insert whatever is specified at the beginning of
#       the flag instances array. To add to the end of the list, use the
#       function 'zparse_flags_add_flag_after'. If you want to add a flag
#       sorted into position, use 'zparse_flags_add_flag'.
#
# prints: <nothing>
# returns: 0 if completed successfully.
#          2 if not enough inputs given (flagname, pos and flag are all
#            mandatory).
function zparse_flags_add_flag_before () {
	if [[ -z $1 ]] ; then
		zparse_flags_print_internal_error $0 1 "require a flag specification."
		return 2
	elif [[ -z $2 ]] ; then
		zparse_flags_print_internal_error $0 2 "require position to add flag."
		return 2
	elif [[ -z $3 ]] ; then
		zparse_flags_print_internal_error $0 3 "require the flag name to add."
		return 2
	fi
	set -A $(zparse_flags_usage_name $1) \
									"$2,$3" ${(P)$(zparse_flags_usage_name $1)}
	if [[ -n $4 ]] ; then
		if [[ ${4[1]} == "<" || ${4[1]} == ">" ]] ; then
			eval $(zparse_flags_inputs_name $1)\[\$2,\$3\]=\":\$4\"
		else
			eval $(zparse_flags_inputs_name $1)\[\$2,\$3\]=\":\>\$4\"
		fi
	else
		eval $(zparse_flags_inputs_name $1)\[\$2,\$3\]=\"_\"
	fi
	:
}

# FUNCTION:  zparse_flags_add_flag_after {flagname} {pos} {flag} [[<,>]input]
#
# add a flag instance to 'flagname'. The format of flag instances in this
# version of parse-flags is:
#   (command-line-position,flag-name[:{<,>}input] ...)
# where 'input' is optional.
# For example:
#   ./binary --help --output=stdout -h
# would have flag instances:
#   help_flag: (1,--help 3,-h)
#   output_flag: (2,--output:<stdout)
#
# To replicate this behaviour, we can issue:
#   zparse_flags_add_flag_after  help_flag 1 --help
#     -> (1,--help)
#   zparse_flags_add_flag_after  help_flag 2 --opt >input
#     -> (2,--opt:>input)
#   zparse_flags_add_flag_after  help_flag 3 --opt <input
#     -> (3,--opt:<input)
#
# Note that 'input' may optionally begin with '<' or '>' to indicate that
# the input was entered on the same argument input or the next one,
# respectively. If ommited, then the function will assume it was given on the
# next input; that is, as if a '>' was given.
#
# Note: this function orders the flag instances in the usage array by
#     	position. To add to the beginning of the list, use the function
#       'zparse_flags_add_flag_before', and to add to the end of the list, use
#       the function 'zparse_flags_add_flag_after'.
#
# prints: <nothing>
# returns: 0 if completed successfully.
#          2 if not enough inputs given (flagname, pos and flag are all
#            mandatory).
function zparse_flags_add_flag () {
	if [[ -z $1 ]] ; then
		zparse_flags_print_internal_error $0 1 "require a flag specification."
		return 2
	elif [[ -z $2 ]] ; then
		zparse_flags_print_internal_error $0 2 "require position to add flag."
		return 2
	elif [[ -z $3 ]] ; then
		zparse_flags_print_internal_error $0 3 "require the flag name to add."
		return 2
	fi
	if zparse_flags_add_flag_after "$@" ; then
		set -A $(zparse_flags_usage_name $1) \
			   "${(@f)$(sort -n <<<${(PF)$(zparse_flags_usage_name $1)})}"
		return 0
	fi
	zparse_flags_print_internal_error $0 "adding flag failed."
	return 2
	# N.B:
	# sorting into numerical order:
	# ${(PF)$(pfun $1)} dereferences ('P') the string returned by pfun and
	# the 'F' flag outputs with newlines instead of a space.
	# So, we will have:
	#     sort -n <<<${usage_parameter}
	# This will sort the contents numerically, and print to stdout with
	# newlines separating the sorted entries. Finally, collect the
	# newline-separated outputs into an array using the 'f' flag to split
	# on newlines _and_ putting the whole thing in quotes to ensure that
	# inputs with whitespace are not separated into distinct entries
}

# FUNCTION:  zparse_flags_combine_flags {newflag} {flag1} {flag2} [flag3...]
#
# create new usage and inputs arrays as if 'newflag' had been given as a
# flag declaration to zparse_flags. Note: the names of these usage and inputs
# arrays is goverened by the 'zparse_flags_usage_rename' and
# 'zparse_flags_inputs_rename' parameters as would be for normal flag
# declarations. Into the new usage and input arrays populate the items
# contained in the flags 'flag1' and 'flag2'...
#
# prints: <nothing>
# returns: 0 if completed successfully
#          2 if not enough inputs given
function zparse_flags_combine_flags () {
	if [[ -z $1 ]] ; then
		zparse_flags_print_internal_error $0 1 "require a flag specification."
		return 2
	elif [[ -z $2 ]] ; then
		zparse_flags_print_internal_error $0 2 "require the flag to combine."
		return 2
	elif [[ -z $3 ]] ; then
		zparse_flags_print_internal_error $0 3 "require the flag to combine."
		return 2
	fi

	local flagname=$1
	shift

	typeset -a temp_usage
	typeset -A temp_inputs
	local i
	for i in $* ; do
		temp_usage+=(${(P)$(zparse_flags_usage_name $i)})
		temp_inputs+=(${(Pkv)$(zparse_flags_inputs_name $i)})
	done

	# sort temp_usage
	temp_usage=(${(@n)temp_usage})


	if [[ -z $zparse_flags_usage_rename ]] ; then
		# set flag usage data
		set -A ${flagname}_usage $temp_usage
		zparse_flags_usage_name_map[${flagname}]="${flagname}_usage"
	else
		# fill in usage data
		local usage_name
		#zparse_flags_internal_debug_print "usage filter: $zparse_flags_usage_rename"

		# if 'zparse_flags_usage_rename' has a '%n' then we just use 'final'
		# as the new parameter to put data in, otherwise we just tack on
		# 'final' to the end of the flag variable.
		if usage_name=$(zparse_flags_internal_construct_rename \
										$zparse_flags_usage_rename $flagname)
		then
			# returned 0, which means will_be_unique is false
			set -A $flagname${usage_name} $temp_usage
			zparse_flags_usage_name_map[${flagname}]=${flagname}${usage_name}
		else
			set -A ${usage_name} $temp_usage
			zparse_flags_usage_name_map[${flagname}]=${usage_name}
		fi
		#zparse_flags_internal_debug_print "usage final: $final"
		#zparse_flags_internal_debug_print "usage unique: $will_be_unique"
	fi


	if [[ -z $zparse_flags_inputs_rename ]] ; then
		# set flag inputs data
		typeset -Ag ${flagname}_inputs
		eval ${flagname}_inputs+=\( \${\(kv\)temp_inputs} \)
		#set -A ${flagname}_inputs \
		#					${(Pkv)${${flagname}_inputs}} ${(kv)temp_inputs}
		zparse_flags_inputs_name_map[${flagname}]="${flagname}_inputs"
	else
		# fill in inputs data
		local inputs_name
		#zparse_flags_internal_debug_print "inputs filter: $zparse_flags_inputs_rename"

		# if 'zparse_flags_inputs_rename' has a '%n' then we just use 'final'
		# as the new parameter to put data in, otherwise we just tack on
		# 'final' to the end of the flag variable.
		if inputs_name=$(zparse_flags_internal_construct_rename \
										$zparse_flags_inputs_rename $flagname)
		then
			# returned 0, which means will_be_unique is false
			typeset -Ag ${flagname}${inputs_name}
			eval ${flagname}${inputs_name}=\( \${\(kv\)temp_inputs} \)
			zparse_flags_inputs_name_map[${flagname}]="${flagname}${inputs_name}"
		else
			typeset -Ag ${inputs_name}
			eval ${inputs_name}=\( \${\(kv\)temp_inputs} \)
			zparse_flags_inputs_name_map[${flagname}]="${inputs_name}"
		fi
		#zparse_flags_internal_debug_print "inputs final: $final"
		#zparse_flags_internal_debug_print "inputs unique: $will_be_unique"
	fi
	:
}


# FUNCTION:  zparse_flags_has_flag_in_recognized_list {flagname}
#
# check to see whether the flagname is in the list of flag variable names
# given to zparse_flags.
#
# prints: <nothing>
# returns: 0 if the flag was found in the list.
#          1 if the list is available but the flag was not found.
#          2 if the list is not available (meaning the variable
#            'zparse_flags_list_recognized_flags' was not exported).
#          3 if not enough arguments were given.
function zparse_flags_has_flag_in_recognized_list () {
	if [[ -z $1 ]] ; then
		zparse_flags_print_internal_error $0 1 "require a flag specification."
		return 3
	fi

	if [[ $zparse_flags_list_recognized_flags != 1 ]] ; then
		zparse_flags_print_internal_error $0 "must first set ${zparse_flags_quote_left}zparse_flags_list_recognized_flags=1${zparse_flags_quote_right}."
		return 2
	elif [[ -z $zparse_flags_list_recognized_flags_name ]] ; then
		(( ! $+zparse_flags_recognized_flag_names[(r)$1] )) && return 1
	else
		[[ -z ${${(P)zparse_flags_list_recognized_flags_name}[(r)$1]} ]] && \
			return 1
	fi
	:
}

# FUNCTION:  zparse_flags_split_input {input} {into_var} [fs]
#            zparse_flags_split_input {input} {into_var} {fs} {ql} {qr}
#
# split the input string with field splitter 'fs' (or else a comma if not
# given) and put the fields into an array called 'into_var'. Note that the
# input string should be the name of the variable containing it and not the
# input iself; so:
#    input_str="some,input"
#    typeset -a output
#    zparse_flags_split_input  input_str  output
# and not:
#    typeset -a output
#    zparse_flags_split_input  "some,input"  output
# The field splitter 'fs' must be a single character that is not a backslash.
# Also, this functions recognizes escaping the field splitter as a means of
# entering that literal character and not as a field-splitting character.
# Finally, any escaped field-splitting character is replaced with an
# unescaped character.
#
# Additionally, the function can be given two characters called 'ql' and
# 'qr'. These must be characters and neither equal to a backslash character.
# When these are given the 'fs' character must be explicitly given. These
# two characters affect the splitting procedure thusly: if directly after the
# 'fs' character the 'ql' character appears, then we no longer search for the
# 'fs' character to split the string but the 'qr' character followed by an
# 'fs' character. E.g., with  fs=","  ql="("  qr=")", the string:
#    abc,de,(f,gh),ij,k
# is split into: abc  de  (f,gh)  ij  k.
# Note, that the third field is "(f,gh)" with the 'fs' character and both
# the 'ql' and 'qr' characters also incuded in the split field.
# Effectively, the 'in'-'out' character pair act like a supplementary field
# splitter.
# When an 'ql'-'qr' character pair are given, all escaped 'ql' or 'qr'
# characters are handled, but within an 'ql'-'qr' field the 'fs' character
# is NOT handled -- only outside of it is it handled.
# Note: the 'ql' and 'qr' characters are really only intended internally for
# zparse_flags: they are used to separate command specifications like:
#    "cm:command=/[ab]/,cd"
# where the idea is to call:
#    zparse_flags_split_input ... , / /
#
# The 'into_var' variable name cannot begin 'zparse_flags_'
# in order that it not conflict with internal variables; and this function
# will append entries into 'into_var' if it is not empty, but will not alter
# what is already there (so, it won't escape out the field separator, for
# example, as it does with the processed 'input').
#
# prints: <nothing>
# returns: 0 for success
#          1 if 'input' is empty, so that there's nothing to do.
#          2 if not enough arguments were passed or they are non-conforming.
function zparse_flags_split_input () {
	if [[ -z $1 ]] ; then
		zparse_flags_print_internal_error $0 1 "require the parameter name of the input to split."
		return 2
	elif [[ -z $2 ]] ; then
		zparse_flags_print_internal_error $0 2 "require a parameter name."
		return 2
	elif [[ ${2[1,13]} == zparse_flags_ ]] ; then
		zparse_flags_print_internal_error $0 2 "parameter name cannot begin ${zparse_flags_quote_left}zparse_flags_${zparse_flags_quote_right}."
		return 2
	fi

	if [[ -z $3 ]] ; then
		local zparse_flags_f=,
	else
		local zparse_flags_f=$3
	fi
	if [[ -z $4 ]] ; then
		if [[ -z $5 ]] ; then
			local zparse_flags_P=""
			local zparse_flags_Q=""
		else
			zparse_flags_print_internal_error $0 4 "missing left-quote character."
			return 2
		fi
	else
		if [[ -z $5 ]] ; then
			zparse_flags_print_internal_error $0 "missing right-quote character."
			return 2
		else
			local zparse_flags_P=$4
			local zparse_flags_Q=$5
		fi
	fi

	if [[ $zparse_flags_f == "\\" ]] ; then
		zparse_flags_print_internal_error $0 3 "field-splitting character cannot be ${zparse_flags_quote_left}\\${zparse_flags_quote_right}."
		return 2
	elif [[ $zparse_flags_P == "\\" ]] ; then
		zparse_flags_print_internal_error $0 4 "left-quote character cannot be ${zparse_flags_quote_left}\\${zparse_flags_quote_right}."
		return 2
	elif [[ $zparse_flags_Q == "\\" ]] ; then
		zparse_flags_print_internal_error $0 5 "right-quote character cannot be ${zparse_flags_quote_left}\\${zparse_flags_quote_right}."
		return 2
	fi

	if (($#zparse_flags_f > 1)) ; then
		zparse_flags_print_internal_error $0 3 "field-splitting character must be a single character: ${zparse_flags_quote_left}$zparse_flags_f${zparse_flags_quote_right}."
		return 2
	elif (($#zparse_flags_P > 1)) ; then
		zparse_flags_print_internal_error $0 3 "left-quote character must be a single character: ${zparse_flags_quote_left}$zparse_flags_P${zparse_flags_quote_right}."
		return 2
	elif (($#zparse_flags_Q > 1)) ; then
		zparse_flags_print_internal_error $0 3 "right-quote character must be a single character: ${zparse_flags_quote_left}$zparse_flags_Q${zparse_flags_quote_right}."
		return 2
	fi

	local zparse_flags_I=${(P)1}
	if [[ -z $zparse_flags_I ]] ; then
		local -a zparse_flags_A
		zparse_flags_A=( '' )
		set -A $2 $zparse_flags_A
		return 0
	fi
	integer zparse_flags_i
	integer zparse_flags_j
	integer zparse_flags_k # records whether an escape has been given
	local -a zparse_flags_A

	# as a guide: fs=: ql=( qr=)
	#
	# ":a::b:" -> [a] [b]
	# "a\:b"   -> [a:b]
	# "\\:\x"  -> [\\] [\x]
	# "a\"     -> [a\]
	#
	# ":(a:b):" -> [(a:b)]  # the ql and qr are left in
	# "\(a,b)" -> [a] [b)]  # unpaired 'qr' left in
	# "(a,b\)" -> [(a] [b)]
	# "" -> []
	# "" -> []
	# "" -> []

	for ((zparse_flags_i=1; zparse_flags_i<=$#zparse_flags_I; zparse_flags_i++))
	do
		if ((zparse_flags_k)) ; then
			zparse_flags_k=0
				# last character was a backslash so we just ignore this
				# character here by doing nothing on this next character
				# except resetting k.
		elif [[ $zparse_flags_I[$zparse_flags_i] == "\\" ]] ; then
			zparse_flags_k=1
		elif [[ $zparse_flags_I[$zparse_flags_i] == $zparse_flags_f ]] ; then
			zparse_flags_A+=(
					$zparse_flags_I[$zparse_flags_j,${zparse_flags_i}-1] )
			zparse_flags_j=$((zparse_flags_i + 1))
		fi
	done
	if ((zparse_flags_j <= $#zparse_flags_I)); then
		zparse_flags_A+=( $zparse_flags_I[$zparse_flags_j,$] )
	fi
	# at this point we have a comma-split array of string with ALL escapes
	# left in. If 'P' and 'Q' are defined (the 'ql' and 'qr' characters),
	# then we need to concatenate the P-Q sequences. That is, if we had an
	# input: "ab,(c,d,e),fg" [fs="," ql="(" qr=")"], then at this point we
	# have:
	#   A = ( "ab"  "(c"  "d"  "e)"  "fg" )
	# First we want to recognize that "(c" starts with an 'ql' character,
	# so we need to keep concatenating fields until we find one whose last
	# character is an 'qr' character (concatenating with the 'fs' character
	# included):
	#   A -> ( "ab"  "(c,d,e)"  "fg" )
	# Note, if we never find an ending 'qr' character, then the last field
	# will be "(w,x,y,z", with it just left out.

	local -a zparse_flags_B
	if [[ -n $zparse_flags_P$zparse_flags_Q ]] ; then
		local zparse_flags_s
		local zparse_flags_t
		for zparse_flags_s in $zparse_flags_A ; do
			if [[ -n $zparse_flags_t ]] ; then
				zparse_flags_t+=$zparse_flags_f$zparse_flags_s
				if [[ $zparse_flags_s[-1] == $zparse_flags_Q \
						&& $zparse_flags_s[-2] != \\ ]]; then
					zparse_flags_B+=$zparse_flags_t
					zparse_flags_t=""
				fi
			elif [[ $zparse_flags_s[1] == $zparse_flags_P \
						&& $zparse_flags_s[-1] != $zparse_flags_Q ]] ; then
				zparse_flags_t=$zparse_flags_s
			else
				zparse_flags_B+=$zparse_flags_s
			fi
		done
		[[ -n $zparse_flags_t ]] && zparse_flags_B+=$zparse_flags_t
	else
		zparse_flags_B=($zparse_flags_A)
	fi

	# now we just need to deal with escapes:
	#   - where an 'ql'-'qr' string is defined:
	#       * inside an 'ql'-'qr' field we remove 'ql' and 'qr' esacpes.
	#       * outside we remove 'ql', 'qr', and 'fs' escapes.
	#   - where only 'fs' defined:
	#       * remove all 'fs' escapes.
	if [[ -z $zparse_flags_P$zparse_flags_Q ]] ; then
		zparse_flags_A=(${zparse_flags_B//\\$zparse_flags_f/$zparse_flags_f})
	else
		zparse_flags_A=()
		for zparse_flags_s in $zparse_flags_B ; do
			if [[ $zparse_flags_s[1] == $zparse_flags_P ]] ; then
				zparse_flags_A+=${${zparse_flags_s//\\$zparse_flags_P/$zparse_flags_P}//\\$zparse_flags_Q/$zparse_flags_Q}
			else
				zparse_flags_A+=${${${zparse_flags_s//\\$zparse_flags_P/$zparse_flags_P}//\\$zparse_flags_Q/$zparse_flags_Q}//\\$zparse_flags_f/$zparse_flags_f}
			fi
		done
	fi

	set -A $2 $zparse_flags_A
	:
}


# FUNCTION:  zparse_flags_split_command {input} [command] [parameter] [fs]
#
# take an input and separate it into a command and an input to that command
# (here called the "parameter"). As with zparse_flags_split_input, the input
# that is to be split must be given to this function as the name of the
# variable containing that input, and not the input itself. The next two
# arguments to the function will be the variable names that this function
# will place the command and parameter into respectively, if they are not
# empty; if they are empty then that command or parameter will not be filled.
# Finally, the field splitter may be given as the last argument, or else the
# default character of an equals sign is used. Again, as with the
# zparse_flags_split_input function, the field splitter must be a single
# character that is not a backslash.
#
# Some examples to illustrate how the input is split:
#     com=param    =>> [com]   [param]
#     com=p=4.3    =>> [com]   [p=4.3]
#     com==param   =>> [com]   [=param]
#     com\==param  =>> [com=]  [param]
#     =com=param   =>> [=com]  [param]
#     \=com\==\=   =>> [=com=] [=]
#
# The 'command' and 'parameter' variable names cannot begin 'zparse_flags_'
# in order that it not conflict with internal variables.
# Note also that this function will overwrite the 'command' and 'parameter'
# variables if they are not empty on entering the function.
#
# prints: <nothing>
# returns: 0 for success
#          1 if 'input' is empty, so that there's nothing to do.
#          2 if not enough arguments were passed or they are non-conforming.
function zparse_flags_split_command () {
	if [[ -z $1 ]] ; then
		zparse_flags_print_internal_error $0 1 "require the parameter name of the input to split."
		return 2
	elif [[ -z $2 && -z $3 ]] ; then
		zparse_flags_print_internal_error $0 "require parameter name(s) to place the output into."
		return 2
	elif [[ ${2[1,13]} == zparse_flags_ ]] ; then
		zparse_flags_print_internal_error $0 2 "parameter name cannot begin ${zparse_flags_quote_left}zparse_flags_${zparse_flags_quote_right}."
		return 2
	elif [[ ${3[1,13]} == zparse_flags_ ]] ; then
		zparse_flags_print_internal_error $0 3 "parameter name cannot begin ${zparse_flags_quote_left}zparse_flags_${zparse_flags_quote_right}."
		return 2
	fi

	if [[ -z $4 ]] ; then
		local zparse_flags_f="="
	else
		local zparse_flags_f=$4
	fi
	if [[ $zparse_flags_f == "\\" ]] ; then
		zparse_flags_print_internal_error $0 4 "field-splitting character cannot be ${zparse_flags_quote_left}\\${zparse_flags_quote_right}."
		return 2
	elif (($#zparse_flags_f > 1)) ; then
		zparse_flags_print_internal_error $0 4 "field-splitting character must be a single character: ${zparse_flags_quote_left}$zparse_flags_f${zparse_flags_quote_right}."
		return 2
	fi

	local zparse_flags_I=${(P)1}
	if [[ -z $zparse_flags_I ]] ; then
		return 1
	fi
	integer zparse_flags_i
	integer zparse_flags_k
	local zparse_flags_C
	local zparse_flags_P
	if [[ $zparse_flags_I[1,2] == \\$zparse_flags_f ]] ; then
		integer zparse_flags_j=3
	else
		integer zparse_flags_j=2
	fi
	for ((zparse_flags_i=$zparse_flags_j; zparse_flags_i<=$#zparse_flags_I; zparse_flags_i++)) ; do
		if ((zparse_flags_k)) ; then
			zparse_flags_k=0
				# escaped field splitter, so ignore field splitter (at I[$i])
				# by doing nothing except resetting k
		else
			if [[ $zparse_flags_I[$zparse_flags_i] == "\\" ]] ; then
				zparse_flags_k=1
			elif [[ $zparse_flags_I[$zparse_flags_i] == $zparse_flags_f ]]
			then
				zparse_flags_C=$zparse_flags_I[1,${zparse_flags_i}-1]
				zparse_flags_P=$zparse_flags_I[${zparse_flags_i}+1,$]
				break
			fi
		fi
	done
	[[ -z $zparse_flags_C ]] && zparse_flags_C=$zparse_flags_I
	zparse_flags_C=${zparse_flags_C//\\$zparse_flags_f/$zparse_flags_f}
	zparse_flags_P=${zparse_flags_P//\\$zparse_flags_f/$zparse_flags_f}
	[[ -n $2 ]] && typeset -g ${2}=$zparse_flags_C

	[[ -n $3 ]] && typeset -g ${3}=$zparse_flags_P
	:
}


function zparse_flags_internal_debug_print () {
	echo "\e[96mDEBUG: ${@}\e[0m"
}



# we must be given, for a flag variable:
#    flag_1: (M -o --output cb:stdout cm:file)
#
# zparse_flags_internal_check_input_specification \
# 		flag_1 <cl_pos> <flag> <clflag_index_start> \
# 		<comsep_$flag_1_flagnum> <cominp_$flag_1_flagnum>
#
# so that:
#   ./script -ofile=./log --output file=./log $comsep $cominp
#            ^ ^                   ^
#            1 3                   1
#
# means the function should be given as, respectively:
#   zparse_flags_internal_check_input_specification flag_1 1 -o 3 , =
#   zparse_flags_internal_check_input_specification flag_1 2 --output 1 , =
#
# all other variables that this function needs are taken from its environment.
# These are:
#    clflag              - the command-line input we are examining
#    $1_commands_specification (e.g. flag_1_commands_specification)
#    error
#    command_name
#    command_input
#    command_input_list
#    regex_spec_open
function zparse_flags_internal_check_input_specification () {
	local -a all_commands
	local -a command_decl
	integer command_match
	integer command_input_given
	integer input_match
	# pficis_clflag is the command input given to the flag under consideration
	# on the command line.
	local pficis_clflag=${clflag[$5,$]}

	# command_input_list is the list of declared commands for the matched
	# flag.
	eval command_input_list=\(\$${1}_commands_specification\)
	# DEBUG: print command_input_list
	#zparse_flags_internal_debug_print "» command_input_list: ($command_input_list)"

	integer command_num
	local comsep=$6
	local cominp=$7
	#zparse_flags_internal_debug_print "flag $1 comsep: $comsep"
	#zparse_flags_internal_debug_print "flag $1 cominp: $cominp"
	if ! zparse_flags_split_input pficis_clflag all_commands $comsep ; then
		zparse_flags_print_internal_error zparse_flags $2 $4 "all commands splitting failed. This is a bug!"
		error=1
		return 1
	fi
	# DEBUG: print all_commands
	#zparse_flags_internal_debug_print "» pficis_clflag: ($pficis_clflag)"
	#zparse_flags_internal_debug_print "» all_commands: ($all_commands)"
	for ((command_num=1; command_num<=$#all_commands; command_num++)) ; do

		pficis_clflag=$all_commands[$command_num]


		if ! zparse_flags_split_command \
					pficis_clflag command_name command_input $cominp
		then
			zparse_flags_print_internal_error zparse_flags $2 $4 "command splitting failed. This is a bug!"
			error=1
			return 1
		fi
		#zparse_flags_internal_debug_print "command: [$command_name]"
		#zparse_flags_internal_debug_print "command input: [$command_input]"
		if [[ $pficis_clflag[(($#command_name + 1))] == $cominp ]] ; then
			command_input_given=1
		else
			command_input_given=0
		fi


		# First, look for the command name in the list of commands:
		command_match=0
		for ((i=1; i<=$#command_input_list; i++)) ; do
			#eval command_decl=\( \$$command_input_list[$i] \)
			command_decl=( ${(P)${command_input_list[i]}} )
			# DEBUG: print command_decl
			#zparse_flags_internal_debug_print "» command_input_list: ($command_input_list)"
			#zparse_flags_internal_debug_print "» command_decl: ($command_decl)"
			if [[ ${command_decl[1][1]} == $regex_spec_open ]] ; then
				if [[ $command_name =~ "^"${command_decl[1][2,-2]} ]] ; then
					if [[ $command_name == $MATCH ]] ; then
						command_match=1
						# increment the command presence count, stored in
						# command_input_list[i][4] (i.e., the fourth index
						# position of the arrays in the command_input_list).
						# Then we need to update our command_decl variable.
						(( ${command_input_list[i]}[4]+=1 ))
						command_decl=( ${(P)${command_input_list[i]}} )
						# DEBUG: print command_decl
						#zparse_flags_internal_debug_print "cd: [$command_decl]"
						break
					fi
				fi
			else
				if [[ ${command_decl[1]} == $command_name ]] ; then
					command_match=1
					# increment the command presence count, stored in
					# command_input_list[i][4] (i.e., the fourth index
					# position of the arrays in the command_input_list).
					# Then we need to update our command_decl variable.
					(( ${command_input_list[i]}[4]+=1 ))
					command_decl=( ${(P)${command_input_list[i]}} )
					# DEBUG: print command_decl
					#zparse_flags_internal_debug_print "cd: [$command_decl]"
					break
				fi
			fi
		done

		if (( ! command_match && $#command_input_list )) ; then
			zparse_flags_print_error $2 $3 "flag ${zparse_flags_quote_left}${4}${zparse_flags_quote_right}: unrecognized command: ${zparse_flags_quote_left}${command_name}${zparse_flags_quote_right}."
			error=1
		# Note: the following code uses a hack to ensure that if
		# command_decl[3] contains "-", then the arithmatic check still
		# executes: we append the digit "0" to both the numerals, which does
		# not affect the comparison if they are both digits, or the latter
		# value of "-" is changed to a number "-0" and the arithmetic code
		# syntax does not fail.
		elif [[ $command_decl[3] != - ]] && \
			 (( ${command_decl[4]}0 > ${command_decl[3]}0 )) ; then
			zparse_flags_print_error $2 $3 "flag ${zparse_flags_quote_left}${4}${zparse_flags_quote_right}: command ${zparse_flags_quote_left}${command_name}${zparse_flags_quote_right} exceeds presence limit."
			error=1
		else
			# if the command name has matched, now check if the command
			# inputs match.
			# First, check to see if it is a B command and it has been
			# given an input:
			if [[ $command_decl[2] == b ]] ; then
				if [[ -n $command_input ]] ; then
					zparse_flags_print_error $2 $3 "flag ${zparse_flags_quote_left}${4}${zparse_flags_quote_right}: command ${zparse_flags_quote_left}${command_name}${zparse_flags_quote_right} does not take an input: ${zparse_flags_quote_left}${command_input}${zparse_flags_quote_right}."
					error=1
				elif ((command_input_given)) ; then
					zparse_flags_print_error $2 $3 "flag ${zparse_flags_quote_left}${4}${zparse_flags_quote_right}: command ${zparse_flags_quote_left}${command_name}${zparse_flags_quote_right} does not take an input."
					error=1
				fi
			else
				if (($#command_decl > 4)) ; then
					input_match=0
					for ((j=5; j<=$#command_decl; j++)) ; do
						if [[ -z $command_input ]] ; then
							if ((command_input_given)) ; then
								zparse_flags_print_error $2 $3 "flag ${zparse_flags_quote_left}${4}${zparse_flags_quote_right}: command ${zparse_flags_quote_left}${command_name}${zparse_flags_quote_right}: expected input not given."
								input_match=1
								error=1
								break
							else
								if [[ $command_decl[2] == o ]] ; then
									input_match=1
									break
								else
									zparse_flags_print_error $2 $3 "flag ${zparse_flags_quote_left}${4}${zparse_flags_quote_right}: command ${zparse_flags_quote_left}${command_name}${zparse_flags_quote_right}: required input is missing."
									input_match=1
									error=1
									break
								fi
							fi
						elif [[ ${command_decl[$j][1]} == $regex_spec_open ]]
						then
							if [[ $command_input \
											=~ "^"${command_decl[$j][2,-2]} ]]
							then
								if [[ $command_input == $MATCH ]] ; then
									input_match=1
									break
								fi
							fi
						else
							if [[ $command_decl[$j] == $command_input ]] ; then
								input_match=1
								break
							fi
						fi
					done

					if (( ! input_match )) ; then
						zparse_flags_print_error $2 $3 "flag ${zparse_flags_quote_left}${4}${zparse_flags_quote_right}: command ${zparse_flags_quote_left}${command_name}${zparse_flags_quote_right}: unrecognized input: ${zparse_flags_quote_left}${command_input}${zparse_flags_quote_right}."
						error=1
					fi
				else
					# not inputs specified. Just make sure an M command
					# has been given an input, and that a floating "="
					# has not been given to either an M or O command.
					if (( ! command_input_given )) ; then
						if [[ $command_decl[2] == m ]] ; then
							zparse_flags_print_error $2 $3 "flag ${zparse_flags_quote_left}${4}${zparse_flags_quote_right}: command ${zparse_flags_quote_left}${command_name}${zparse_flags_quote_right}: required input is missing."
							error=1
						fi
					elif [[ -z $command_input ]] ; then
						zparse_flags_print_error $2 $3 "flag ${zparse_flags_quote_left}${4}${zparse_flags_quote_right}: command ${zparse_flags_quote_left}${command_name}${zparse_flags_quote_right}: expected input not given."
						error=1
					fi
				fi
			fi
		fi

	done
}

# NOTE: The functions ‘zparse_flags_internal_add_to_I’,
#       ‘zparse_flags_internal_add_to_A’ and ‘zparse_flags_internal_add_to_U’
#       add flags in the format: ‘num,_{IAU}[S]:>{input}’. In particular:
#         1. the flag part of the specification is ‘_{IAU}[S]’ where the ‘S’
#            is appended if the input was added after a stop flag.
#         2. all the inputs are declared as external, ‘:>’.
function zparse_flags_internal_add_to_I() {
	clflag_handled_by_I=1
	if (( ! flag_I_number )) ; then
		# we have no limit on I: flag was declared as `I'.
		eval flag_info_$have_flag_var_I+=\(\"$((clnum - decflagN - 1)),_I\$1\"\)
		eval flag_info_input_$have_flag_var_I\[$((clnum - decflagN - 1)),_I\$1\]=\":\>${clflag}\"
	else
		# we have a limit on I: flag was declared as `I#'.
		if (( flag_I_count <= flag_I_number ))
		then
			eval flag_info_$have_flag_var_I+=\(\"$((clnum - decflagN - 1)),_I\$1\"\)
			eval flag_info_input_$have_flag_var_I\[$((clnum - decflagN - 1)),_I\$1\]=\":\>${clflag}\"
			flag_I_count=$((flag_I_count + 1))
		else
			zparse_flags_print_error $((clnum - decflagN - 1)) "surplus input: ${zparse_flags_quote_left}${clflag}${zparse_flags_quote_right}."
			error=1
		fi
	fi
}

function zparse_flags_internal_add_to_A() {
	clflag_handled_by_A=1
	if (( ! flag_A_number )) ; then
		# we have no limit on A: flag was declared as `A'.
		eval flag_info_$have_flag_var_A+=\(\"$((clnum - decflagN - 1)),_A\$1\"\)
		eval flag_info_input_$have_flag_var_A\[$((clnum - decflagN - 1)),_A\$1\]=\":\>${clflag}\"
	else
		# we have a limit on A: flag was declared as `A#'.
		if (( flag_A_count <= flag_A_number )) ; then
			eval flag_info_$have_flag_var_A+=\(\"$((clnum - decflagN - 1)),_A\$1\"\)
			eval flag_info_input_$have_flag_var_A\[$((clnum - decflagN - 1)),_A\$1\]=\":\>${clflag}\"
			flag_A_count=$((flag_A_count + 1))
		else
			zparse_flags_print_error $((clnum - decflagN - 1)) "surplus input: ${zparse_flags_quote_left}${clflag}${zparse_flags_quote_right}."
			error=1
		fi
	fi
}

function zparse_flags_internal_add_to_U() {
	clflag_handled_by_U=1
	if (( ! flag_U_number )) ; then
		# we have no limit on U: flag was declared as `U'.
		eval flag_info_$have_flag_var_U+=\(\"$((clnum - decflagN - 1)),_U\$1\"\)
		eval flag_info_input_$have_flag_var_U\[$((clnum - decflagN - 1)),_U\$1\]=\":\>${clflag}\"
	else
		# we have a limit on U: flag was declared as `U#'.
		if (( flag_U_count <= flag_U_number )) ; then
			eval flag_info_$have_flag_var_U+=\(\"$((clnum - decflagN - 1)),_U\$1\"\)
			eval flag_info_input_$have_flag_var_U\[$((clnum - decflagN - 1)),_U\$1\]=\":\>${clflag}\"
			flag_U_count=$((flag_U_count + 1))
		else
			zparse_flags_print_error $((clnum - decflagN - 1)) "surplus input: ${zparse_flags_quote_left}${clflag}${zparse_flags_quote_right}."
			error=1
		fi
	fi
}

function zparse_flags_internal_add_to_IAU_flags() {
	# Third, if we haven't continued in the BOM flag search, then we
	# have an unrecognized flag. Let's put it in any A/I/U flags that
	# may exist.
	###integer clflag_handled_by_U
	if [[ -n $have_flag_var_U ]] ; then
		# Because U is a universal accepter, then we don't need to
		# check for stop_parsing.

		zparse_flags_internal_add_to_U
	fi

	###integer clflag_handled_by_A
	if [[ -n $have_flag_var_A && ${clflag[1]} == - ]] ; then
		# since the A flag captures all flag inputs, we don't need to
		# check for a stop parsing flag since this is captured anyway.

		zparse_flags_internal_add_to_A
	fi

	###integer clflag_handled_by_I
	if [[ -n $have_flag_var_I && ${clflag[1]} != - ]] ; then
		zparse_flags_internal_add_to_I
	elif [[ -n $have_flag_var_I && -n $stop_parsing ]] ; then
		zparse_flags_internal_add_to_I S
	fi
}

# zparse_flags_internal_construct_rename <input> <flagname>
#
# input: $zparse_flags_usage_rename|$zparse_flags_inputs_rename
# flagname: e.g: "flag_B"
#
# output: the final rename string <RENAME>
# exits: 0 - if RENAME is not unique (will be identical for all flagnames)
#        1 - if RENAME is unique (if it incorporates flagname somehow)
#
#
# DO NOT CALL this function if $1 is empty. Also, $2 should NOT be empty.
function zparse_flags_internal_construct_rename () {
	local rename=$1
	local flagname=$2
	integer escaper
	integer will_be_unique
	local final

	for ((j=1; j<=$#rename; j++)) ; do
		if ((escaper)); then
			escaper=0
			if [[ $rename[$j] == % ]] ; then
				# we will ignore the "%%" sequence
				#final+=%
				:
			elif [[ $rename[$j] == n ]] ; then
				#eval final+=\$$i
				final+=$flagname
				will_be_unique=1
			else
				# we will ignore the unrecognized "%..." sequence
				#final+="%${zparse_flags_usage_rename[$j]}"
				:
			fi
		elif [[ $rename[$j] == % ]] ; then
			escaper=1
		else
			#eval final+=\$\{${i}\[$j\]\}
			final+=$rename[$j]
		fi
	done

	echo - $final
	return will_be_unique
}



# There are two sets of flags that we will be working with: the declared
# flag variables (B, O, M, etc.) and the command-line flags (in $@). We 
# will refer to the declared flags as "decflag" and the command-line flags
# as "clflag".
function zparse_flags () {

	# the next two strings MUST be one character in length (or else there
	# will be undefined behaviour); they indicate the characters used to
	# mark a regex string as the opening character and closing character.
	# That is, "{abc}" marks a regex string "abc" if regex_spec_open="{" and
	# regex_spec_close="}". These are only used internally for convenience.
	local regex_spec_open=/
	local regex_spec_close=/

	integer decflagN
		# number of declared flags
	integer decflagstart=1
		# declared flags start at pos 1

	integer i
	integer j
	integer k
		# loop variables used many times for _integer_ values _only_.
	local str
		# another loop variable.

	# check to see if zparse_flags has been given enough inputs
	if (($# < 2)) ; then
		zparse_flags_print_internal_error $0 "need a list of flag specifications and the list of command-line arguments."
		return 2
	fi

	# check to see if the first argument is a (valid) number: id est, a
	# positive whole number
	integer format_ok
	local zparse_flags_input
	for ((i=$decflagstart; i<=$#; i++)) ; do
		zparse_flags_input=${(P)i}
		if [[ $zparse_flags_input == "---" ]] ; then
			format_ok=1
			decflagN=$((i - 1))
			break
		fi
	done
	if ((!format_ok)) ; then
		zparse_flags_print_internal_error $0 "flag specifications must be separated from command-line arguments with ${zparse_flags_quote_left}---${zparse_flags_quote_right}."
		return 2
	fi
	unset format_ok
	unset zparse_flags_input


	# OK, first we'll parse the flag variables because we need complete
	# information on what has been given when we decide what to do with
	# a particular argument. We'll also check to see if the flag variable's
	# declaration (B, O, M, I, A, U or S) has only been given, and whether
	# for the I and A flag declarations there is nothing else in the array.
	# So, let's get on with it: we'll declare some has_flag_var's:
	typeset -a decflag     # utility variable to store declared flag info
	typeset -a BOMSlist    # the command-line positions of the BOMS flags
	for str in I A U ; do  # set if we find that type of flag
		local have_flag_var_$str
	done
	integer flag_A_number # the number declared of the I A or U flags, if
	integer flag_I_number # given. If the range is unlimited (there is no
	integer flag_U_number # number in the declaration), then this is unset.
	integer error # set to non-zero if any error is found, or else zero.
	integer have_actual_flag # we'll use this to check that a flag
							 # declaration contains some actual flags.
	local decl_command
	local command_name
	local command_input
	local -a command_input_list


	for ((i=$decflagstart; i<$((decflagN + decflagstart)); i++)) ; do
		local comsep_${i}=${zparse_flags_comsep:-\,}
			# flag command variable. Used to specify the character
			# that separates flag commands: --flag=com1,com2,...
		#eval XX=\$comsep_$i
		#zparse_flags_internal_debug_print "X comsep: [$XX]"
		local cominp_${i}=${zparse_flags_cominp:-=}
			# flag command variable. Used to specify the character
			# that separates command inputs from commands: --flag=com=x
			#                                                        ^
		#eval XX=\$cominp_$i
		#zparse_flags_internal_debug_print "Y cominp: [$XX]"
		local flaginp_${i}=${zparse_flags_flaginp:-=}
			# flag variable. Used to specify the character that separates
			# a flag from its input: --flag=inputs...
			#                              ^
		#eval XX=\$flaginp_$i
		#zparse_flags_internal_debug_print "Z flaginp: [$XX]"

		# DEBUG: print decflag
		#zparse_flags_internal_debug_print "» i: ($i)"
		#zparse_flags_internal_debug_print "» (P)i: (${(P)i})"
		#zparse_flags_internal_debug_print "» (PP)i: (${(P)${(P)i}})"
		# set decflag to the ith flag declaration along with the name of
		# the variable holding that information. E.g.,
		#   decflag=(flag5 B -h --help)
		decflag=(${(P)i} ${(P)${(P)i}})
		# -> eval decflag= \( $5     \$ $5  \)   for, e.g., i=5
		# -> decflag=(flag5 $flag5)
		#           =(flag5 B -h --help)
		#
		# DEBUG: print decflag
		#zparse_flags_internal_debug_print "» decflag: ($decflag)"

		if [[ ${decflag[2]} =~ "^[BOM][0-9]*" || ${decflag[2]} == S ]] ; then

			BOMSlist+=($i)

			# we will put any specified commands in the current declared
			# flag in an array named after the declared flag name. E.g.,
			#   flag1:   (O -o --option cb:com1 co3:com2=in1,in2)
			#   decflag: (flag1 O -o --option cb:com1 co:com2=in1,in2)
			#   flag1_commands_specification:
			#            (flag1_command_5 flag1_command_6)
			#
			# and the arrays "flag1_command_5" and "flag1_command_6" will
			# contain:
			#   flag1_command_5:  (com1 b - #)
			#   flag1_command_6:  (com2 o 3 # in1 in2)
			# where the "#" is a number that records how many times that
			# command has appeared so far.
			local -a ${decflag[1]}_commands_specification

			have_actual_flag=0
			for ((j=3; j<=$#decflag; j++)) ; do
				if [[ -z ${decflag[$j]} ]] ; then
					zparse_flags_print_internal_error $0 $i ${decflag[1]} "contains an empty input at position $((j-2))."
					error=1
				elif [[ ${decflag[2]} =~ "^[BOM][0-9]*" || ${decflag[2]} == S ]]
				then

					# check whether the flag/command specification is
					# conforming or not.
					if [[ ${decflag[$j][1,3]} == "s:$regex_spec_open" || \
							${decflag[$j][1,3]} == "l:$regex_spec_open" ]]
					then
						if [[ ${decflag[$j][-1]} != $regex_spec_close ]] ; then
							zparse_flags_print_internal_error $0 $i ${decflag[1]} "position $((j-2)): ${zparse_flags_quote_left}${decflag[$j]}${zparse_flags_quote_right}: regex flag name not terminated with a regex specifier ‘$regex_spec_close’."
							error=1
						else
							have_actual_flag=1
						fi
					elif [[ ${decflag[$j][1,2]} == "${regex_spec_open}-" ]]
					then
						# bollocks to escaping. If it ends in '/', then it's
						# a regex.
						if [[ ${decflag[$j][-1]} != $regex_spec_close ]] ; then
							zparse_flags_print_internal_error $0 $i ${decflag[1]} "position $((j-2)): ${zparse_flags_quote_left}${decflag[$j]}${zparse_flags_quote_right}: regex flag name not terminated with a regex specifier ‘$regex_spec_close’."
							error=1
						elif [[ ${decflag[$j][3]} == "{" ]] ; then
							zparse_flags_print_internal_error $0 $i ${decflag[1]} "position $((j-2)): ${zparse_flags_quote_left}${decflag[$j]}${zparse_flags_quote_right}: regex flag that has a bound on an initial ‘-’ should have its type explicitly declared (‘l:’ or ‘s:’)."
							error=1
						elif [[ ${decflag[$j][3,4]} == "-{" ]] ; then
							zparse_flags_print_internal_error $0 $i ${decflag[1]} "position $((j-2)): ${zparse_flags_quote_left}${decflag[$j]}${zparse_flags_quote_right}: regex flag that has a bound on an initial ‘--’ should have its type explicitly declared (‘l:’ or ‘s:’)."
							error=1
						else
							have_actual_flag=1
						fi
					elif [[ ${decflag[$j][1]} == "-" || \
							${decflag[$j][1,2]} == "s:" || \
							${decflag[$j][1,2]} == "l:" ]] ; then
						have_actual_flag=1
					elif [[ ${decflag[$j]} =~ "^cb[0-9]*:" || \
						    ${decflag[$j]} =~ "^co[0-9]*:" || \
						    ${decflag[$j]} =~ "^cm[0-9]*:" ]] ; then
						# let's examine whether the command specification
						# is conforming.
						decl_command=${decflag[$j][(($#MATCH + 1)),$]}
						## DEBUG : print decflag
						#zparse_flags_internal_debug_print "decflag: [$decflag]"
						## DEBUG : print decl_command
						#zparse_flags_internal_debug_print "decl_command: [$decl_command]"
						if [[ -z $decl_command ]] ; then
							zparse_flags_print_internal_error $0 $i ${decflag[1]} "position $((j-2)): ${zparse_flags_quote_left}${decflag[$j]}${zparse_flags_quote_right}: command specification is empty."
							error=1
						else
							if ! zparse_flags_split_command decl_command \
															command_name \
															command_input
							then
								zparse_flags_print_internal_error $0 $i ${decflag[1]} "position $((j-2)): ${zparse_flags_quote_left}${decflag[$j]}${zparse_flags_quote_right}: command splitting failed. This is a bug!"
								error=1
							fi
							## DEBUG : print command_name
							#zparse_flags_internal_debug_print "command_name: [$command_name]"
							# bollocks to escaping. If it ends in a '/' it's
							# a regex.
							if [[ $command_name[1] == $regex_spec_open && \
								  $command_name[-1] != $regex_spec_close ]]
							then
								zparse_flags_print_internal_error $0 $i ${decflag[1]} "position $((j-2)): ${zparse_flags_quote_left}${decflag[$j]}${zparse_flags_quote_right}: regex command name ${zparse_flags_quote_left}${command_name}${zparse_flags_quote_right} not terminated with a regex specifier ‘$regex_spec_close’."
								error=1
							fi
							# if command is a B command, then there can be
							# no inputs:
							if [[ ${decflag[$j][2]} == b ]] ; then
								if [[ $decl_command[(($#command_name + 1))] \
									  == "=" ]]
								then
									zparse_flags_print_internal_error $0 $i ${decflag[1]} "position $((j-2)): ${zparse_flags_quote_left}${decflag[$j]}${zparse_flags_quote_right}: declared bare command cannot take an input."
									error=1
								fi
							elif [[ -z $command_input &&
								$decl_command[(($#command_name + 1))] == "=" ]]
							then
								zparse_flags_print_internal_error $0 $i ${decflag[1]} "position $((j-2)): ${zparse_flags_quote_left}${decflag[$j]}${zparse_flags_quote_right}: input specification to command name ${zparse_flags_quote_left}${command_name}${zparse_flags_quote_right} is empty."
								error=1
							fi
							if [[ -n $command_input ]] ; then
								command_input_list=()
								if ! zparse_flags_split_input \
										command_input \
										command_input_list \
										, $regex_spec_open $regex_spec_close
								then
									zparse_flags_print_internal_error $0 $i ${decflag[1]} "position $((j-2)): ${zparse_flags_quote_left}${decflag[$j]}${zparse_flags_quote_right}: command input splitting failed. This is a bug!"
									error=1
								fi
								for str in $command_input_list ; do
									# bollocks to escaping. If it ends in a '/'
									# it's a regex.
									if [[ $str[1] == $regex_spec_open && \
								  		  $str[-1] != $regex_spec_close ]]
									then
										zparse_flags_print_internal_error $0 $i ${decflag[1]} "position $((j-2)): ${zparse_flags_quote_left}${decflag[$j]}${zparse_flags_quote_right}: regex input specification ${zparse_flags_quote_left}${str}${zparse_flags_quote_right} not terminated with a regex specifier ‘$regex_spec_close’."
										error=1
									fi
								done
								# decflag: (flag1 O -o cb:com1 co:com2=x,y)
								# pos:        1   2  3    4        5
								#
								# we will create local arrays called
								# "command_3" and "command_4" that will
								# contain the command specifications and
								# they themselves will be recorded in an
								# array called:
								#   "flag1_commands_specification"
								# containing: (command_3 command_4)
								#
								# If the command is O or M, then the
								# command_N array will contain:
								#  (command_name [o|m] [<N>|-] [C] [inputs...])
								# where C is the number of times the command
								# has been given;
								# and if the command is B...
								local -a ${decflag[1]}_command_$j
								if (($#MATCH > 3)) ; then
									eval ${decflag[1]}_command_$j+=\(\$command_name \"${decflag[$j][2]}\" \"${MATCH[3,-2]}\" 0\)
								else
									eval ${decflag[1]}_command_$j+=\(\$command_name \"${decflag[$j][2]}\" \- 0\)
								fi
								eval ${decflag[1]}_command_$j+=\(\$command_input_list\)
							else
								# ...if the command is B, the command_N
								# array will contain:
								#  (command_name b [<N>|-] [C])
								local -a ${decflag[1]}_command_$j
								if (($#MATCH > 3)) ; then
									eval ${decflag[1]}_command_$j+=\(\$command_name \"${decflag[$j][2]}\" \"${MATCH[3,-2]}\" 0\)
								else
									eval ${decflag[1]}_command_$j+=\(\$command_name \"${decflag[$j][2]}\" \- 0\)
								fi
							fi
							eval ${decflag[1]}_commands_specification+=\(${decflag[1]}_command_$j\)
						fi
					elif [[ ${decflag[$j]} =~ "^f:" ]] ; then
						# let's examine whether the command specification
						# is conforming.
						decl_command=${decflag[$j][(($#MATCH + 1)),$]}
						## DEBUG : print decflag
						#zparse_flags_internal_debug_print "decflag: [$decflag]"
						## DEBUG : print decl_command
						#zparse_flags_internal_debug_print "decl_command: [$decl_command]"
						if [[ -z $decl_command ]] ; then
							zparse_flags_print_internal_error $0 $i ${decflag[1]} "position $((j-2)): ${zparse_flags_quote_left}${decflag[$j]}${zparse_flags_quote_right}: command option is empty."
							error=1
						else
							if ! zparse_flags_split_command decl_command \
															command_name \
															command_input
							then
								zparse_flags_print_internal_error $0 $i ${decflag[1]} "position $((j-2)): ${zparse_flags_quote_left}${decflag[$j]}${zparse_flags_quote_right}: command splitting failed. This is a bug!"
								error=1
							else
								## DEBUG : print command_name
								#zparse_flags_internal_debug_print "command_name: [$command_name]"
								#zparse_flags_internal_debug_print "command_input: [$command_input]"

								if [[ $command_name == comsep ]] ; then
									if [[ -z $command_input ]] ; then
										if [[ ${decl_command[$#command_name + 1]} == '=' ]] ; then
											zparse_flags_print_internal_error $0 $i ${decflag[1]} "position $((j-2)): ${zparse_flags_quote_left}${decflag[$j][$#MATCH + 1,-2]}${zparse_flags_quote_right}: not given an input."
										else
											zparse_flags_print_internal_error $0 $i ${decflag[1]} "position $((j-2)): ${zparse_flags_quote_left}${decflag[$j][$#MATCH + 1,$]}${zparse_flags_quote_right}: not given an input."
										fi
										error=1
									else
										eval comsep_${i}=\$command_input 
										#eval zparse_flags_internal_debug_print "\"set comsep_${i}: [\${comsep_${i}}]\""
									fi
								elif [[ $command_name == cominp ]] ; then
									if [[ -z $command_input ]] ; then
										if [[ ${decl_command[$#command_name + 1]} == '=' ]] ; then
											zparse_flags_print_internal_error $0 $i ${decflag[1]} "position $((j-2)): ${zparse_flags_quote_left}${decflag[$j][$#MATCH + 1,-2]}${zparse_flags_quote_right}: not given an input."
										else
											zparse_flags_print_internal_error $0 $i ${decflag[1]} "position $((j-2)): ${zparse_flags_quote_left}${decflag[$j][$#MATCH + 1,$]}${zparse_flags_quote_right}: not given an input."
										fi
										error=1
									else
										eval cominp_${i}=\$command_input 
										#eval zparse_flags_internal_debug_print "\"set cominp_${i}: [\${cominp_${i}}]\""
									fi
								elif [[ $command_name == flaginp ]] ; then
									if [[ -z $command_input ]] ; then
										if [[ ${decl_command[$#command_name + 1]} == '=' ]] ; then
											zparse_flags_print_internal_error $0 $i ${decflag[1]} "position $((j-2)): ${zparse_flags_quote_left}${decflag[$j][$#MATCH + 1,-2]}${zparse_flags_quote_right}: not given an input."
										else
											zparse_flags_print_internal_error $0 $i ${decflag[1]} "position $((j-2)): ${zparse_flags_quote_left}${decflag[$j][$#MATCH + 1,$]}${zparse_flags_quote_right}: not given an input."
										fi
										error=1
									else
										eval flaginp_${i}=\$command_input 
										#eval zparse_flags_internal_debug_print "\"set cominp_${i}: [\${cominp_${i}}]\""
									fi
								else
									zparse_flags_print_internal_error $0 $i ${decflag[1]} "position $((j-2)): ${zparse_flags_quote_left}${decflag[$j][$#MATCH+1,$]}${zparse_flags_quote_right}: command option not recognized."
									error=1
								fi
							fi
						fi
					else
						zparse_flags_print_internal_error $0 $i ${decflag[1]} "has an invalid flag declared at position $((j-2)): flag ${zparse_flags_quote_left}${decflag[$j]}${zparse_flags_quote_right} must begin with ${zparse_flags_quote_left}-${zparse_flags_quote_right}, ${zparse_flags_quote_left}s:${zparse_flags_quote_right}, ${zparse_flags_quote_left}l:${zparse_flags_quote_right} or ${zparse_flags_quote_left}c[bom]:${zparse_flags_quote_right}."
						error=1
					fi
				fi
			done
			if ((!have_actual_flag && !error)); then
				zparse_flags_print_internal_error $0 $i ${decflag[1]} "declared without any flags."
				error=1
			fi
		elif [[ ${decflag[2]} == I || ${decflag[2]} == A || \
			    ${decflag[2]} == U ]] ; then
			eval have_flag_var_${decflag[2]}=\$i
			# don't set flag_[IAU]_number to any value: leave it unset.
			if (( $#decflag > 2 )) ; then
				zparse_flags_print_internal_error $0 $i ${decflag[1]} "should not have other inputs other than the declaration of the flag's type (${zparse_flags_quote_left}${decflag[2]}${zparse_flags_quote_right})."
				error=1
			fi
		elif [[ ${decflag[2]} =~ '^[IAU][1-9][0-9]*' ]]; then
			eval have_flag_var_${decflag[2][1]}=\$i
			integer IAU_number=$(sed "s|${decflag[2][1]}"'\(.*\)|\1|' <<< "${decflag[2]}")
			eval flag_${decflag[2][1]}_number=\$IAU_number
			if (( $#decflag > 2 )) ; then
				zparse_flags_print_internal_error $0 $i ${decflag[1]} "should not have other inputs other than the declaration of the flag's type (${zparse_flags_quote_left}${decflag[2]}${zparse_flags_quote_right})."
				error=1
			fi
		else
			# at this point the flag can be empty or invalid. Let's first
			# check if it's empty:
			if [[ -z $decflag[2] ]] ; then
				# if it's empty, we ignore it by default unless the variable
				# 'zparse_flags_strict_flag_declarations' is set to 1
				if [[ $zparse_flags_strict_flag_declarations == 1 ]] ; then
					zparse_flags_print_internal_error $0 $i ${decflag[1]} "not a valid flag declaration."
					error=1
				fi
			# if the flag declaration is invalid, then print an error:
			else
				zparse_flags_print_internal_error $0 $i ${decflag[1]} "not a valid flag variable: ${zparse_flags_quote_left}${decflag[2]}${zparse_flags_quote_right}."
				error=1
			fi
		fi
	done



	# Well, that's all the checks done. Let's look at `error' and exit if
	# we've found any problems.
	((error)) && return 2


	# Now, let's begin parsing the input...



	# OK, first of all, for every flag1 ... flagN passed, we declare
	# a sister variable, flag_info_1 ... flag_info_N. We do this since
	# we need to keep the contents of flagI (i.e. "B" "-s" "--sharp")
	# intact during the parsing procedure, but also need to record when a
	# flag declared in flagI has been encountered; so, we put this info in
	# flag_info_I. What we'll do is replace flagI with flag_info_I once
	# all the parsing is done.
	# Thus, flag_info_N contains our flag instance data. This is the data
	# that the zparse_flags function essentially returns.
	for ((i=$decflagstart; i<$((decflagN + decflagstart)); i++)) ; do
		typeset -a flag_info_$i
		typeset -A flag_info_input_$i
		# flag_info_input_N contains the input to the flags given in
		# flag_info_N.
		typeset -a flag_supp_info_$i
		# flag_supp_info_N contains supplementary data for the flag.
		# That is, flag N as the $N input to this zparse_flags function
		# being, for example, "B -h --help", we will record instance data
		# in flag_info_1 and supplementary data to the flag in
		# flag_supp_info_1. Information recorded at index position is:
		#   1: how many times the flag has been given.
	done



	local stop_parsing # set if we no longer parse for flags, but inputs.
	typeset -a take_input_on_next_iteration # contains information to be...
			# ...remembered when we take an input to an M flag that has
			# ...appeared on the next command-line position.

	# decflagnum is the position on the command line of the BOMS flag under
	# consideration, and decflag_small is a helper variable for recording
	# declare flag information.
	integer decflagnum
	typeset -a decflag_small
	# These count how many I A and U inputs have been found. We'll compare
	# this count with the declared max number:
	for str in I A U ; do
		integer flag_${str}_count=1
	done
	# The command-line flag and its number:
	integer clnum
	local clflag
	integer chain_count

	local -a must_be_a_flag

	integer pBOMS # used in the following for loop itself as a loop variable.
	integer flag_A_count=1
	integer flag_I_count=1
	integer flag_U_count=1
	integer clflag_handled_by_I
	integer clflag_handled_by_A
	integer clflag_handled_by_U

	# set to 1 when a flag limit has been set and exceeded
	# i.e., flag=(B2 -x ...)
	# ./run -x -x -x  <-- third instance exceeds limit of 2.
	local flag_exceed=0

	# set to the flag input character for the flag under consideration.
	local flaginp

	## DEBUG : print BOMSlist
	#zparse_flags_internal_debug_print "@ BOMSlist: [$BOMSlist]"

	for ((clnum=$((decflagN + 2)); clnum<=$#; clnum++)) ; do
		clflag=${(P)clnum}
		## DEBUG : print clflag
		#zparse_flags_internal_debug_print "@ * clnum: $clnum"
		#zparse_flags_internal_debug_print "@ * clflag: $clflag"

		# if the flag was such that an input was expected on the next
		# command-line input, e.g., --output /file, then
		# take_input_on_next_iteration will have been set  and we
		# just take the input on this next iteration as the input and
		# update flag_info_. Having done this we continue to the next
		# command-line input.
		if [[ -n $take_input_on_next_iteration ]] ; then
			# take_input_on_next_iteration[i]:
			#  i=1: flagnum
			#  		  the integer position of the flag declaration given to
			#  		  zparse_flags (so a pointer to a variable like 'help_flag',
			#  		  which contains all information for that flag declaration.
			#  i=2: argument position
			#  		  cl position of flag under parsing inspection
			#  i=3: chain number
			#  		  cl chain number of flag under parsing inspection
			#  i=4: flag
			#  		  cl flag under inspection (extracted from the cl input if
			#         chained or attached to input)
			#  i=5: comsep
			#         the command separator for the flagnum flag,
			#         comsep_$flagnum
			#  i=6: comsep
			#         the command input separator for the flagnum flag,
			#         cominp_$flagnum
			if (($take_input_on_next_iteration[3] > 1)) ; then
				eval flag_info_${take_input_on_next_iteration[1]}+=\(\"${take_input_on_next_iteration[2]}.${take_input_on_next_iteration[3]},${take_input_on_next_iteration[4]}\"\)
				typeset "flag_info_input_${take_input_on_next_iteration[1]}[${take_input_on_next_iteration[2]}.${take_input_on_next_iteration[3]},${take_input_on_next_iteration[4]}]"=":>${clflag}"
			else
				eval flag_info_${take_input_on_next_iteration[1]}+=\(\"${take_input_on_next_iteration[2]},${take_input_on_next_iteration[4]}\"\)
				typeset "flag_info_input_${take_input_on_next_iteration[1]}[${take_input_on_next_iteration[2]},${take_input_on_next_iteration[4]}]"=":>${clflag}"
			fi

			zparse_flags_internal_check_input_specification \
									${(P)take_input_on_next_iteration[1]} \
									$take_input_on_next_iteration[2] \
									$take_input_on_next_iteration[3] \
									$take_input_on_next_iteration[4] 1 \
									$take_input_on_next_iteration[5] \
									$take_input_on_next_iteration[6]

			take_input_on_next_iteration=()
			continue
		fi

		must_be_a_flag=()

		chain_count=0
		clflag_handled_by_I=0
		clflag_handled_by_A=0
		clflag_handled_by_U=0

		flag_exceed=0 # reset flag_exceed

		# First, we'll look to see if the clflag matches one of the BOM flags
		# The array BOMSlist is the list of B/O/M/S flags declared to the
		# program by function argument number. When we are examining a clflag,
		# we need to compare it to these declared B/O/M/S flag specifications.
		for ((pBOMS=1; pBOMS<=$#BOMSlist; pBOMS++)) ; do
			decflagnum=${BOMSlist[$pBOMS]}
			eval flaginp=\$flaginp_${decflagnum}
			## DEBUG : print decflagnum
			#zparse_flags_internal_debug_print "decflagnum: $decflagnum"
			#zparse_flags_internal_debug_print "flaginp: |$flaginp|"

			# decflag_small is the flag declaration prepended with the
			# flag name holding the declaration:
			#   flag_h=(B9 -h ...)
			#   => decflag_small: (flag_h B9 -h ...)  [for now...]
			decflag_small=(${(P)decflagnum} ${(P)${(P)decflagnum}})
			if (( $#decflag_small[2] > 1 )) ; then
				decflag_small=( ${decflag_small[1]} \
								${decflag_small[2][1]} \
								${decflag_small[2][2,$]} \
								${decflag_small[3,$]} )
			else
				decflag_small=( ${decflag_small[1]} \
								${decflag_small[2]} \
								- \
								${decflag_small[3,$]} )
			fi
			## DEBUG : print decflag_small
			#zparse_flags_internal_debug_print "decflag small: $decflag_small"
			for ((j=4; j<=$#decflag_small; j++)) ; do
				# E.g.,
				#   help_flag=(B9 -h --help)
				# sets:
				#   decflag_small=(help_flag B 9 -h --help s:h)
				#   decflag=(help_flag B 1 s -h)     <-- loop j=3
				#   decflag=(help_flag B 2 l --help) <-- loop j=4
				#   decflag=(help_flag B 3 s h)      <-- loop j=5
				if [[ ${decflag_small[$j]} =~ "^c[bom][0-9]*:" ]] ; then
					continue
				elif [[ ${decflag_small[$j][1,2]} == "s:" ]] ; then
					if [[ ${decflag_small[$j][3]} == $regex_spec_open ]] ; then
						decflag=(${decflag_small[1]} ${decflag_small[2]} \
								 $((j - 3)) s ${decflag_small[$j][4,-2]} R)
					else
						decflag=(${decflag_small[1]} ${decflag_small[2]} \
								 $((j - 3)) s ${decflag_small[$j][3,$]} x)
					fi
				elif [[ ${decflag_small[$j][1,2]} == "l:" ]] ; then
					if [[ ${decflag_small[$j][3]} == $regex_spec_open ]] ; then
						decflag=(${decflag_small[1]} ${decflag_small[2]} \
								 $((j - 3)) l ${decflag_small[$j][4,-2]} R)
					else
						decflag=(${decflag_small[1]} ${decflag_small[2]} \
								 $((j - 3)) l ${decflag_small[$j][3,$]} x)
					fi
				elif [[ ${decflag_small[$j][1,2]} == "--" ]] ; then
					decflag=(${decflag_small[1]} ${decflag_small[2]} \
							 $((j - 3)) l ${decflag_small[$j]} x)
				elif [[ ${decflag_small[$j][1,3]} == "${regex_spec_open}--" ]]
				then
					decflag=(${decflag_small[1]} ${decflag_small[2]} \
							 $((j - 3)) l ${decflag_small[$j][2,-2]} R)
				elif [[ ${decflag_small[$j][1]} == $regex_spec_open ]] ; then
					decflag=(${decflag_small[1]} ${decflag_small[2]} \
							 $((j - 3)) s ${decflag_small[$j][2,-2]} R)
				else
					decflag=(${decflag_small[1]} ${decflag_small[2]} \
							 $((j - 3)) s ${decflag_small[$j]} x)
				fi

				# if decflag is '-', ALWAYS interpret it as long, even if
				# it was declared as 's:-'. If interpreted as a short flag,
				# then if clflag is '--x' (x=anything), then it will hit
				# the first '-' and then since there is more input,
				# interpret the next flags as a chain and so it will
				# record the first '-' and with what is left ('-x') prepend
				# a '-' to unchain the flag, and so get '--x' again. It will
				# thus get stuck in an infinite loop. A single flag called
				# '-' will cause problems as a short flag anyway, so let's
				# always interpret it as long.
				[[ ${decflag[5]} == - ]] && decflag[4]=l

				## DEBUG : print decflag
				#zparse_flags_internal_debug_print "  * decflag: $decflag"

				if [[ ${decflag[2]} = S && -z $stop_parsing ]] ; then
					# Does the clflag (CL input) match this declared
					# S flag?
					if [[ \
					   ($decflag[6] == R &&
						(
						 ($clflag =~ "^$decflag[5]" && $MATCH == $clflag)
						 ||
						 ($decflag[4] == s && $clflag =~ "^$decflag[5]")
						 ||
						 ($decflag[4] == l && 
						  $clflag =~ "^${decflag[5]}${flaginp}") 
					    )
					   )
					   ||
					   ($decflag[6] == x && $clflag == ${decflag[5]} ) ]]
					then
						[[ $decflag[6] == R ]] && \
							decflag[5]=${MATCH//$flaginp/}

						stop_parsing=1
						eval flag_info_$decflagnum+=\($((clnum - decflagN - 1)),\"${decflag[5]}\"\)
						typeset "flag_info_input_${decflagnum}[$((clnum - decflagN - 1)),${decflag[5]}]"=_
						continue 3
					fi

				elif [[ ${decflag[2]} = B ]] ; then
					# Does the clflag (CL input) match this declared
					# B flag?
					if [[ ($decflag[6] == R &&
						   (
							($clflag =~ "^$decflag[5]" && $MATCH == $clflag)
							||
							($decflag[4] == s && $clflag =~ "^$decflag[5]")
							||
							($decflag[4] == l && \
							 $clflag =~ "^${decflag[5]}${flaginp}")
						   )
						  )
						  ||
						  ($decflag[6] == x &&
						   ${clflag[1,${#decflag[5]}]} == ${decflag[5]} ) ]]
					then
						eval k=\$\#flag_info_$decflagnum
						# k is the number of times the flag has already been
						# given, which is just the number of array entries in
						# the flag_info_#### variable. We need to check that
						# this is less than any declared maximum flag number
						# as well:
						## DEBUG : print decflag_small
						#zparse_flags_internal_debug_print \
						#	"decflag given: $k times before now."
						#zparse_flags_internal_debug_print \
						#	"decflag limit: $decflag_small[3]."
						#zparse_flags_internal_debug_print \
						#	"decflag small: $decflag_small"
						#zparse_flags_internal_debug_print "-----------------"

						[[ $decflag_small[3] != "-" ]] && \
						   (( $k >= ${decflag_small[3]} )) && \
						   ((++flag_exceed))

						[[ $decflag[6] == R ]] && \
							decflag[5]=${MATCH//$flaginp/}

						# If after a stop parsing flag, we only need to
						# put the flag into any I, A and U flags.
						# LABEL: label:B_stop (don't delete me!)
						if [[ -n $stop_parsing ]] ; then
							[[ -n $have_flag_var_I ]] && \
								zparse_flags_internal_add_to_I S
							[[ -n $have_flag_var_A ]] && \
								zparse_flags_internal_add_to_A S
							[[ -n $have_flag_var_U ]] && \
								zparse_flags_internal_add_to_U S
							break 2
						fi

						# catch non-chaining bare flags:
						# print unrecognized input of '-h' flag in
						# cl input '-hHH' where '-H' is non-chaining
						# and we have just hit the first '-H' flag
						# in the chain now; so, we look back at the
						# recorded flag information for the last
						# chained bare flag and print an error under
						# that flag details (in must_be_a_flag):
						if ((chain_count > 0)) && [[ $decflag[4] == l ]]
						then
							if [[ $clflag[1] == - ]] ; then
								zparse_flags_print_error $must_be_a_flag[2] $chain_count "flag ${zparse_flags_quote_left}$must_be_a_flag[3]${zparse_flags_quote_right}: flag does not take an input: ${zparse_flags_quote_left}$clflag[2,$]${zparse_flags_quote_right}."
							else
								zparse_flags_print_error $must_be_a_flag[2] $chain_count "flag ${zparse_flags_quote_left}$must_be_a_flag[3]${zparse_flags_quote_right}: flag does not take an input: ${zparse_flags_quote_left}$clflag${zparse_flags_quote_right}."
							fi
							error=1
							continue 3
						fi

						# nothing beyond 'flag':
						if [[ ${#clflag} == ${#decflag[5]} ]] ; then
							# if we have cl flag -hh then the first bare
							# flag is chained at the chain_count variable
							# will have value 1. Now, when we hit the
							# second bare flag we will be here at this
							# point of the code and we need to set the
							# flag information to "1.2" instead of "1":

							# but first, if we've exceeded the flag limit,
							# then print the error and skip
							if ((flag_exceed)) ; then
								zparse_flags_print_error $((clnum - decflagN - 1)) $((chain_count + 1)) "flag ${zparse_flags_quote_left}$decflag[5]${zparse_flags_quote_right}: given too many times."
								error=1
								continue 3
							fi

							if ((chain_count == 0)) ; then
								eval flag_info_$decflagnum+=\($((clnum - decflagN - 1)),\"${decflag[5]}\"\)
								typeset "flag_info_input_${decflagnum}[$((clnum - decflagN - 1)),${decflag[5]}]"=_
							else
								eval flag_info_$decflagnum+=\($((clnum - decflagN - 1)).$((chain_count + 1)),\"${decflag[5]}\"\)
								typeset "flag_info_input_${decflagnum}[$((clnum - decflagN - 1)).$((chain_count + 1)),${decflag[5]}]"=_
							fi
							continue 3
						# chain:
						else
							# If the next character is an '=', so we
							# had -h=... then we don't chain but
							# print an error message:
							if [[ $clflag[((${#decflag[5]} + 1))] == $flaginp ]]
							then
								if [[ -z $clflag[((${#decflag[5]} + 2)),$] ]]
								then
									zparse_flags_print_error $((clnum - decflagN - 1)) $((chain_count + 1)) "flag ${zparse_flags_quote_left}$decflag[5]${zparse_flags_quote_right}: flag does not take an input."
								else
									zparse_flags_print_error $((clnum - decflagN - 1)) $((chain_count + 1)) "flag ${zparse_flags_quote_left}$decflag[5]${zparse_flags_quote_right}: flag does not take an input: ${zparse_flags_quote_left}$clflag[((${#decflag[5]} + 2)),$]${zparse_flags_quote_right}."
								fi
								error=1
								continue 3
							fi
							# Now we actually chain if we have an s-flag:
							if ((flag_exceed)) ; then
								zparse_flags_print_error $((clnum - decflagN - 1)) $((chain_count + 1)) "flag ${zparse_flags_quote_left}$decflag[5]${zparse_flags_quote_right}: given too many times."
								error=1
								#continue 3
							fi
							if [[ $decflag[4] == s ]] ; then
								eval flag_info_$decflagnum+=\($((clnum - decflagN - 1)).$((++chain_count)),\"${decflag[5]}\"\)
								typeset "flag_info_input_${decflagnum}[$((clnum - decflagN - 1)).$((chain_count)),${decflag[5]}]"=_
								# if we have shortflags: 'abc', then
								# change to 'bc'. Otherwise, if we have
								# shortflags: '-abc', then change to '-bc'
								if [[ ${decflag[5][1]} == - ]] ; then
									clflag=-${clflag[((${#decflag[5]} + 1)),$]}
								else
									clflag=${clflag[((${#decflag[5]} + 1)),$]}
								fi
								# Now, since this is a B flag, the
								# following inputs MUST be a flag,
								# otherwise the remaining input (now in
								# cflag) must be flagged as invalid inputs
								# attempted to be given to a B flag. So,
								# let's set a variable to watch for this
								# situation
								must_be_a_flag=($decflagnum \
												$((clnum - decflagN - 1)) \
												${decflag[5]})
								pBOMS=0
								continue 2
							fi
						fi
					fi
				else
					# decflag: -o
					# clflag:  -o##### (maybe just '-o')
					if [[ ($decflag[6] == R && ( ($clflag =~ "^$decflag[5]" && $MATCH == $clflag) || ($decflag[4] == s && $clflag =~ "^$decflag[5]") || ($decflag[4] == l && $clflag =~ "^${decflag[5]}${flaginp}") ) ) || ($decflag[6] == x && (${clflag[1,${#decflag[5]}]} == ${decflag[5]}) ) ]]
					then
						[[ $decflag[6] == R ]] && \
							decflag[5]=${MATCH//$flaginp/}

						eval k=\$\#flag_info_$decflagnum
						# k is the number of times the flag has already been
						# given, which is just the number of array entries in
						# the flag_info_#### variable. We need to check that
						# this is less than any declared maximum flag number
						# as well:
						## DEBUG : print decflag_small
						#zparse_flags_internal_debug_print \
						#	"decflag given: $k times before now."
						#zparse_flags_internal_debug_print \
						#	"decflag limit: $decflag_small[3]."
						#zparse_flags_internal_debug_print \
						#	"decflag small: $decflag_small"
						#zparse_flags_internal_debug_print "-----------------"

						[[ $decflag_small[3] != "-" ]] && \
						   (( $k >= ${decflag_small[3]} )) && \
						   ((++flag_exceed))

						# If after a stop parsing flag, we only need to
						# put the flag into any I, A and U flags.
						# LABEL: label:B_stop (don't delete me!)
						if [[ -n $stop_parsing ]] ; then
							[[ -n $have_flag_var_I ]] && \
								zparse_flags_internal_add_to_I S
							[[ -n $have_flag_var_A ]] && \
								zparse_flags_internal_add_to_A S
							[[ -n $have_flag_var_U ]] && \
								zparse_flags_internal_add_to_U S
							break 2
						fi

						# If given too many times, then print an error
						if ((flag_exceed)) ; then
							zparse_flags_print_error $((clnum - decflagN - 1)) $((chain_count + 1)) "flag ${zparse_flags_quote_left}$decflag[5]${zparse_flags_quote_right}: given too many times."
							error=1
							continue 3
						fi

						# clflag: -o/--opt
						if [[ ${#clflag} = ${#decflag[5]} ]] ; then
							if [[ ${decflag[2]} = O ]] ; then
								if ((chain_count == 0)) ; then
									eval flag_info_$decflagnum+=\($((clnum - decflagN - 1)),\"${decflag[5]}\"\)
									typeset "flag_info_input_${decflagnum}[$((clnum - decflagN - 1)),${decflag[5]}]"=_
								else
									eval flag_info_$decflagnum+=\($((clnum - decflagN - 1)).$((chain_count + 1)),\"${decflag[5]}\"\)
									typeset "flag_info_input_${decflagnum}[$((clnum - decflagN - 1)).$((chain_count + 1)),${decflag[5]}]"=_
								fi
								continue 3
							else
								eval "take_input_on_next_iteration=(\$decflagnum  \$((clnum - decflagN - 1)) \$((chain_count + 1))  \${decflag[5]} \"\$comsep_${decflagnum}\" \"\$cominp_${decflagnum}\")"
								continue 3
								:
							fi
						else
							# clflag: -o####/--opt####
							# if short flag, then just capture everything
							# after the flag:
							if [[ ${decflag[4]} = s ]] ; then
								if ((chain_count == 0)) ; then
									eval flag_info_$decflagnum+=\($((clnum - decflagN - 1)),\"${decflag[5]}\"\)
									typeset "flag_info_input_${decflagnum}[$((clnum - decflagN - 1)),${decflag[5]}]"=":<${clflag[$((${#decflag[5]} + 1)),$]}"
								else
									eval flag_info_$decflagnum+=\($((clnum - decflagN - 1)).$((chain_count + 1)),\"${decflag[5]}\"\)
									typeset "flag_info_input_${decflagnum}[$((clnum - decflagN - 1)).$((chain_count + 1)),${decflag[5]}]"=":<${clflag[$((${#decflag[5]} + 1)),$]}"
								fi
								eval zparse_flags_internal_check_input_specification ${(P)decflagnum} $((clnum - decflagN - 1)) $((++chain_count)) ${decflag[5]} $((${#decflag[5]} + 1)) \${comsep_$decflagnum} \${cominp_$decflagnum}
								continue 3
							else  # l-type (long) flag
								# clflag: --opt=#### (maybe just '--opt=')
								if [[ ${clflag[$((${#decflag[5]} + 1))]} \
									  == $flaginp ]] ; then
									# --opt=input
									if (( $#clflag > ${#decflag[5]} + 1))
									then
										if ((chain_count == 0)) ; then
											eval flag_info_$decflagnum+=\($((clnum - decflagN - 1)),\"${decflag[5]}\"\)
											typeset "flag_info_input_${decflagnum}[$((clnum - decflagN - 1)),${decflag[5]}]"=":<${clflag[$((${#decflag[5]} + 2)),$]}"
										else
											eval flag_info_$decflagnum+=\($((clnum - decflagN - 1)).$((chain_count + 1)),\"${decflag[5]}\"\)
											typeset "flag_info_input_${decflagnum}[$((clnum - decflagN - 1)).$((chain_count + 1)),${decflag[5]}]"=":<${clflag[$((${#decflag[5]} + 2)),$]}"
										fi
										eval zparse_flags_internal_check_input_specification ${(P)decflagnum} $((clnum - decflagN - 1)) $((++chain_count)) ${decflag[5]} $((${#decflag[5]} + 2)) \${comsep_$decflagnum} \${cominp_$decflagnum}
										continue 3
									# --opt=
									else
										# no need to get a chain number
										# here since it only ever applies
										# for short flags
										zparse_flags_print_error $((clnum - decflagN - 1)) "flag ${zparse_flags_quote_left}$decflag[5]${zparse_flags_quote_right}: expected input not given."
										error=1
										continue 3
									fi
								else
									# clflag: --optinput
									continue
								fi
							fi
						fi
					fi
				fi
			done
		done
		##zparse_flags_internal_debug_print "must_be_a_flag:3: $must_be_a_flag"

		# If "must_be_a_flag" is still set, we print an error:
		if [[ -n $must_be_a_flag ]] ; then
			if [[ $clflag[1] == - ]] ; then
				zparse_flags_print_error $must_be_a_flag[2] $chain_count "flag ${zparse_flags_quote_left}$must_be_a_flag[3]${zparse_flags_quote_right}: flag does not take an input: ${zparse_flags_quote_left}${clflag[2,$]}${zparse_flags_quote_right}."
			else
				zparse_flags_print_error $must_be_a_flag[2] $chain_count "flag ${zparse_flags_quote_left}$must_be_a_flag[3]${zparse_flags_quote_right}: flag does not take an input: ${zparse_flags_quote_left}$clflag${zparse_flags_quote_right}."
			fi
			error=1
			continue
		fi

		# Third, if we haven't continued in the BOM flag search, then we
		# have an unrecognized flag. Let's put it in any A/I/U flags that
		# may exist.
		# However, we don't want to capture the input if we've already
		# captured it because we're after a stop flag. See ‘label:B_stop’.
		if (( clflag_handled_by_U == 0 && \
			  clflag_handled_by_A == 0 && \
			  clflag_handled_by_I == 0 ))
		then
			zparse_flags_internal_add_to_IAU_flags
		fi

		# Finally, if we reach this point and clflag_handled_by_* has not been
		# set, then we have an unrecognized flag.
		if (( clflag_handled_by_U == 0 && \
			  clflag_handled_by_A == 0 && \
			  clflag_handled_by_I == 0 ))
		then

			if [[ ${clflag[1]} == - ]] ; then
				zparse_flags_print_error $((clnum - decflagN - 1)) "unrecognized flag: ${zparse_flags_quote_left}${clflag}${zparse_flags_quote_right}."
			else
				zparse_flags_print_error $((clnum - decflagN - 1)) "unrecognized argument: ${zparse_flags_quote_left}${clflag}${zparse_flags_quote_right}."
			fi
			error=1
		fi

		# continue 3



	done
	if [[ -n $take_input_on_next_iteration ]] ; then
		# take_input_on_next_iteration[i]:
		#  i=1: flagnum - the integer position of the flag declaration given
		#                 to zparse_flags (so a pointer to a variable like
		#                 'help_flag', which contains all information for that
		#                 flag declaration.
		#  i=2: argument position - cl position of flag under parsing inspection
		#  i=3: chain number - cl chain number of flag under parsing inspection
		#  i=4: flag - cl flag under inspection (extracted from the cl input if
		#              chained or attached to input)
		#  i=5: comsep_$decflagnum - the command separator for this flag
		#  i=6: cominp_$decflagnum - the command input separator for this flag
		zparse_flags_print_error $take_input_on_next_iteration[2] $take_input_on_next_iteration[3] "flag ${zparse_flags_quote_left}${take_input_on_next_iteration[4]}${zparse_flags_quote_right} needs an input."
		error=1
	fi


	typeset -Ag zparse_flags_usage_name_map
	typeset -Ag zparse_flags_inputs_name_map
	local final
	for ((i=$decflagstart; i<$((decflagN + decflagstart)); i++)) ; do
		if [[ -z $zparse_flags_usage_rename ]] ; then
			# set flag usage data
			eval ${(P)i}_usage=\(\$flag_info_$i\)
			zparse_flags_usage_name_map[${(P)i}]="${(P)i}_usage"
			#set -A "zparse_flags_usage_name_map[${(P)i}]"="${(P)i}_usage"
		else
			# fill in usage data
			final=""
			#zparse_flags_internal_debug_print "usage filter: $zparse_flags_usage_rename"

			# if 'zparse_flags_usage_rename' has a '%n' then we just use 'final'
			# as the new parameter to put data in, otherwise we just tack on
			# 'final' to the end of the flag variable.
			if final=$(zparse_flags_internal_construct_rename \
											$zparse_flags_usage_rename ${(P)i})
			then
				# returned 0, which means will_be_unique is false
				eval eval \$\{${i}\}${final}=\\\(\\\$flag_info_$i\\\)
				#eval zparse_flags_usage_name_map\[\$$i\]=\"\$\{${i}\}${final}\"
				zparse_flags_usage_name_map[${(P)i}]=${(P)i}${final}
			else
				eval ${final}=\(\$flag_info_$i\)
				#eval zparse_flags_usage_name_map\[\$$i\]=\"${final}\"
				zparse_flags_usage_name_map[${(P)i}]=$final
			fi
			#zparse_flags_internal_debug_print "usage final: $final"
			#zparse_flags_internal_debug_print "usage unique: $will_be_unique"
		fi

		if [[ -z $zparse_flags_inputs_rename ]] ; then
			# set flag inputs data
			typeset -Ag ${(P)i}_inputs
			eval ${(P)i}_inputs+=\( \${\(kv\)flag_info_input_$i} \)
			zparse_flags_inputs_name_map[${(P)i}]="${(P)i}_inputs"
		else
			# fill in inputs data
			final=""
			#zparse_flags_internal_debug_print "inputs filter: $zparse_flags_inputs_rename"

			# if 'zparse_flags_inputs_rename' has a '%n' then we just use
			# 'final' as the new parameter to put data in, otherwise we just
			# tack on 'final' to the end of the flag variable.
			if final=$(zparse_flags_internal_construct_rename \
										$zparse_flags_inputs_rename ${(P)i})
			then
				# returned 0, which means will_be_unique is false
				typeset -Ag ${(P)i}${final}
				eval ${(P)i}${final}=\( \$\{\(kv\)flag_info_input_$i\} \)
				zparse_flags_inputs_name_map[${(P)i}]=${(P)i}${final}
			else
				typeset -Ag ${final}
				eval ${final}=\( \${\(kv\)flag_info_input_$i} \)
				zparse_flags_inputs_name_map[${(P)i}]=$final
			fi
			#zparse_flags_internal_debug_print "inputs final: $final"
			#zparse_flags_internal_debug_print "inputs unique: $will_be_unique"
		fi
	done


	# let's finally give a list of the variable names declaring flags if we've
	# been told to:
	if [[ $zparse_flags_list_recognized_flags == 1 ]] ; then
		if [[ -z $zparse_flags_list_recognized_flags_name ]] ; then
			zparse_flags_recognized_flag_names=()
			for ((i=$decflagstart; i<$((decflagN + decflagstart)); i++)) ; do
				zparse_flags_recognized_flag_names+=(${(P)i})
			done
		else
			eval $zparse_flags_list_recognized_flags_name=\(\)
			for ((i=$decflagstart; i<$((decflagN + decflagstart)); i++)) ; do
				eval $zparse_flags_list_recognized_flags_name+=\(\"${(P)i}\"\)
			done
		fi
	fi


	((error)) && return 1
	return 0
}
