# zparse\_flags

[![Build Status](https://travis-ci.com/definitelyprobably/zparse_flags.svg?branch=master)](https://travis-ci.com/definitelyprobably/zparse_flags)

This plugin can parse command-line inputs for zsh scripts. Primarily it exists because I preferred to write my own command-line parser than have to read how to make getopts do what I needed. One benefit of this plugin is that error messages are handled by the plugin for you.

## Installation

To install the plugin locally (in `~/.zsh/plugins/zparse_flags`), then run

```sh
$ make install-local
```

To install the plugin system-wide (in `/usr/local/share/zparse_flags`), then run:

```sh
$ make install-system
```

To manually install the plugin to any directory you wish:

```sh
$ mkdir -p /target/path
$ cp zparse_flags /target/path
$ cp zparse_flags.skeleton /target/path
$ cp zparse_flags.zsh /target/path/zparse_flags.0.0.0
```

where the file `zparse_flags.zsh` should be renamed as above after its version number.

## Loading the plugin

To use the plugin, source the file `zparse_flags`:

```sh
#!/bin/zsh
source ~/.zsh/plugins/zparse_flags/zparse_flags
```

This will load the functions from the newest versioned `zparse_flags.X.Y.Z` file present in the directory the `zparse_flags` file is located in.

If multiple versions of the plugin are present, and a specific version is required, then set the parameter `zparse_flags_req`:

```sh
#!/bin/zsh
zparse_flags_req=0
source ~/zsh/plugins/zparse_flags/zparse_flags
```

This will load the newest version of the plugin that is backwards compatible with the requested version.

## Examples

Flags are specified as arrays, which are then passed to the function `zparse_flags`, which does the parsing. Flags are classified as either *bare*, meaning they should not take an input, *optional*, meaning they can take an input, or *mandatory*, meaning that they must take an input.

Determining whether flags have been passed on the command-line is handled by the functions `zparse_flags_has_flag` and `zparse_flags_get_input`.

### Example 1: Basic usage

```sh
#!/bin/zsh
# file name: ./test.zsh

zparse_flags_req=0
source ~/.zsh/plugins/zparse_flags/zparse_flags

# define the 'bare' flag '-h' and its synonym '--help'
# pick any parameter name you wish
flag1=(B -h --help)

# define the 'optional' flag '--log' and its synonym '-l'
# 'optional' means that the following forms will be accepted:
#    -l
#    --log
#    -lfile
#    --log=file
# where 'file' is called the input to the flag
flag2=(O --log -l)

# define the 'mandatory' flag '-o' and its synonyms '-O' and '--output'
# 'mandatory' means that the following forms will be accepted:
#    -o file
#    -ofile
#    -O file
#    -Ofile
#    --output file
#    --output=file
# where 'file' is called the input to the flag
flag3=(M -o -O --output)


# pass the flags defined above to 'zparse_flags', then '---', followed by the
# inputs to the script in order to carry out the parsing. If parsing errors
# were found, then 'zparse_flags' will emit error messages automatically to
# stderr (fd 2) and will return non-zero.

if ! zparse_flags flag1 flag2 flag3 --- $@
then
	exit 1
fi


# check if -h/--help was present
if zparse_flags_has_flag flag1; then
	echo - "    + flag -h/--help was present"
fi

# check if -l/--log was present and get its input, if present
if zparse_flags_has_flag flag2; then

	# check if the optional flag has been given an input or not
	if ! log_file=$(zparse_flags_get_input flag2); then
		echo - "    + flag -l/--log was present"
	else
		echo - "    + flag -l/--log was present with input: $log_file"
	fi
fi

# check if -o/-O/--output was present
# mandatory flags don't need the check the return value of
# 'zparse_flags_get_input' since a mandatory flag missing an input will have
# been caught as an error by 'zparse_flags' above
if zparse_flags_has_flag flag3; then
	echo - "    + flag -o/-O/--output present with input: $(zparse_flags_get_input flag3)"
fi
```

Output:

```sh
$ ./test.zsh -h -l
    +   flag -h/--help was present
    +   flag -l/--log was present

$ ./test.zsh -lfile1 -o file2
    +   flag -l/--log was present with input: file1
    +   flag -o/-O/--output present with input: file2

$ ./test.zsh --log=file1 -ofile2
    +   flag -l/--log was present with input: file1
    +   flag -o/-O/--output present with input: file2

$ ./test.zsh -hlfile
    +   flag -h/--help was present
    +   flag -l/--log was present with input: file

$ ./test.zsh -ho file
    +   flag -h/--help was present
    +   flag -o/-O/--output present with input: file

$ ./test.zsh -o file1 -o file2 -o file3
    +   flag -o/-O/--output present with input: file3


## error messages are handled automatically:

$ ./test.zsh -h -X -Y --zflag
error: arg 2: unrecognized flag: ‘-X’.
error: arg 3: unrecognized flag: ‘-Y’.
error: arg 4: unrecognized flag: ‘--zflag’.

$ ./test.zsh --help=all
error: arg 1: flag ‘--help’: flag does not take an input: ‘all’.

$ ./test.zsh -hXYZ
error: arg 1: flag ‘-h’: flag does not take an input: ‘XYZ’.

$ ./test.zsh -o
error: arg 1: flag ‘-o’ needs an input.


## caveats

# optional flags must have its input attached to the flag, otherwise
# it will conclude no input was given to the flag:

$ ./test.zsh -hl file
error: arg 2: unrecognized argument: ‘file’.

$ ./ test.zsh -hlfile
  +   flag -h/--help was present
  +   flag -l/--log was present with input: file

# mandatory flags are always 'greedy', the next argument will always
# interpreted as its input:

$ ./test.zsh -o -h
  +   flag -o/-O/--output present with input: -h
```

### Example 2: Capturing non-flag arguments

Any command-line input to the script, which will be called an *argument* to the script, is classified as being either a *flag* if it begins with '-', or an *input* otherwise. (Command-line *inputs* should not be confused with the flag *inputs*.)

```sh
#!/bin/zsh
# file name: ./test.zsh

zparse_flags_req=0
source ~/.zsh/plugins/zparse_flags/zparse_flags

flag_h=(B -h --help)
flag_l=(O -l --log)
flag_o=(M -o -O --output)

# to capture all non-flag arguments, create a parameter with value 'I'
# and pass this to 'zparse_flags' along with all recognized flags.
inputs=I


if ! zparse_flags flag_h flag_l flag_o inputs --- $@
then
	exit 1
fi


if zparse_flags_has_flag flag_h; then
	echo - "    + flag -h/--help was present"
fi

if zparse_flags_has_flag flag_l; then

	if ! log_file=$(zparse_flags_get_input flag_l); then
		echo - "    + flag -l/--log was present"
	else
		echo - "    + flag -l/--log was present with input: $log_file"
	fi
fi

if zparse_flags_has_flag flag_o; then
	echo - "    + flag -o/-O/--output present with input: $(zparse_flags_get_input flag_o)"
fi

if zparse_flags_has_flag inputs; then
	echo - "    + last input: $(zparse_flags_get_input inputs)"

	# get an array of all non-flag arguments
	#
	# call 'zparse_flags_get_all_inputs' with the first argument being
	# the array parameter you want to fill, here called 'all', and the
	# second argument being the flag you wish to get all inputs for:
	typeset -a all
	zparse_flags_get_all_inputs inputs all
	echo - "    + all non-flag arguments: $all"
fi
```

Output:

```sh
$ ./test.zsh -h A B -o file C D
    + flag -h/--help was present
    + flag -o/-O/--output present with input: file
    + last input: D
    + all non-flag arguments: A B C D

$ ./test.zsh -h A B -o file C D -E
error: arg 8: unrecognized flag: ‘-E’.
```

### Example 3: Capturing non-recognized flags

If for example, you would like to handle a set of flags as native to your script and pass on the rest to an external program, it is possible to capture all these flags separately.

```sh
#!/bin/zsh
# file name: ./test.zsh

zparse_flags_req=0
source ~/.zsh/plugins/zparse_flags/zparse_flags

flag_h=(B -h --help)
flag_l=(O -l --log)
flag_o=(M -o -O --output)

inputs=I

# in example 2 any argument that began with '-' was recognized as a
# flag, and an error message was printed. To capture these flags,
# pass a paramter with value 'A' to 'zparse_flags':
other_flags=A

# to capture all inputs and non-recognized flags, pass a parameter
# with value 'U' to 'zparse_flags':
inputs_and_other_flags=U


if ! zparse_flags flag_h flag_l flag_o \
                  inputs other_flags inputs_and_other_flags --- $@
then
	exit 1
fi


if zparse_flags_has_flag flag_h; then
	echo - "    + flag -h/--help was present"
fi

if zparse_flags_has_flag flag_l; then

	if ! log_file=$(zparse_flags_get_input flag_l); then
		echo - "    + flag -l/--log was present"
	else
		echo - "    + flag -l/--log was present with input: $log_file"
	fi
fi

if zparse_flags_has_flag flag_o; then
	echo - "    + flag -o/-O/--output present with input: $(zparse_flags_get_input flag_o)"
fi

if zparse_flags_has_flag inputs; then
	echo - "    + last input: $(zparse_flags_get_input inputs)"

	typeset -a all
	zparse_flags_get_all_inputs inputs all
	echo - "    + all non-flag arguments: $all"
fi

if zparse_flags_has_flag other_flags; then
	typeset -a all_other_flags
	zparse_flags_get_all_inputs other_flags all_other_flags
	echo - "    + all non-recognized flags: $all_other_flags"
fi

if zparse_flags_has_flag inputs_and_other_flags; then
	typeset -a all_together
	zparse_flags_get_all_inputs inputs_and_other_flags all_together
	echo - "    + all inputs and non-recognized flags: $all_together"
fi
```

Output:

```sh
$ ./test.zsh -h A B -o file C D -E F -G -h
    + flag -h/--help was present
    + flag -o/-O/--output present with input: file
    + last input: F
    + all non-flag arguments: A B C D F
    + all non-recognized flags: -E -G
    + all inputs and non-recognized flags: A B C D -E F -G
```

### Example 4: Restricting number of appearances

Restricting the number of times flags and inputs should appear on the command-line.

```sh
#!/bin/zsh
# file name: ./test.zsh

zparse_flags_req=0
source ~/.zsh/plugins/zparse_flags/zparse_flags

# all the flag specifications can be restricted in the number of times
# they can appear on the command-line by appending that number to the
# flag specification:

flag_h=(B1 -h --help)
flag_l=(O2 -l --log)
flag_o=(M1 -o -O --output)
inputs=I3
other_flags=A2
inputs_and_other_flags=U4


if ! zparse_flags flag_h flag_l flag_o \
                  inputs other_flags inputs_and_other_flags --- $@
then
	exit 1
fi


if zparse_flags_has_flag flag_h; then
	echo - "    + flag -h/--help was present"
fi

if zparse_flags_has_flag flag_l; then

	if ! log_file=$(zparse_flags_get_input flag_l); then
		echo - "    + flag -l/--log was present"
	else
		echo - "    + flag -l/--log was present with input: $log_file"
	fi
fi

if zparse_flags_has_flag flag_o; then
	echo - "    + flag -o/-O/--output present with input: $(zparse_flags_get_input flag_o)"
fi

if zparse_flags_has_flag inputs; then
	echo - "    + last input: $(zparse_flags_get_input inputs)"

	typeset -a all
	zparse_flags_get_all_inputs inputs all
	echo - "    + all non-flag arguments: $all"
fi

if zparse_flags_has_flag other_flags; then
	typeset -a all_other_flags
	zparse_flags_get_all_inputs other_flags all_other_flags
	echo - "    + all non-recognized flags: $all_other_flags"
fi

if zparse_flags_has_flag inputs_and_other_flags; then
	typeset -a all_together
	zparse_flags_get_all_inputs inputs_and_other_flags all_together
	echo - "    + all inputs and non-recognized flags: $all_together"
fi
```

Output:

```sh
$./test.zsh -h
    + flag -h/--help was present

$ ./test.zsh -h -h
error: arg 2: flag ‘-h’: given too many times.

$ ./test.zsh -o file
    + flag -o/-O/--output present with input: file

$ ./test.zsh -o file -o file
error: arg 3: flag ‘-o’: given too many times.

$ ./test.zsh -X -Y
    + all non-recognized flags: -X -Y
    + all inputs and non-recognized flags: -X -Y

$ ./test.zsh -X -Y -Z
error: arg 3: surplus input: ‘-Z’.

$ ./test.zsh A B C
    + last input: C
    + all non-flag arguments: A B C
    + all inputs and non-recognized flags: A B C

$ ./test.zsh A B C D
error: arg 4: surplus input: ‘D’.

$ ./test.zsh A B C -D
    + last input: C
    + all non-flag arguments: A B C
    + all non-recognized flags: -D
    + all inputs and non-recognized flags: A B C -D

$ ./test.zsh A B C -D -E
error: arg 5: surplus input: ‘-E’.
```

### Example 5: including \-\- and \- flags

```sh
#!/bin/zsh
# file name: ./test.zsh

zparse_flags_req=0
source ~/.zsh/plugins/zparse_flags/zparse_flags

flag_h=(B1 -h --help)
flag_l=(O2 -l --log)
flag_o=(M1 -o -O --output)
inputs=I3
other_flags=A2
inputs_and_other_flags=U4

# introducing the special flag '--', which stops interpreting arguments
# as flags, can be done by passing a parameter with value 'S' to
# 'zparse_flags'. The flag need not be named '--' and other acceptable
# synonyms can also be declared, such as '--stop' and '-S', here.
# Beyond declaration, and passing it to 'zparse_flags', nothing more needs
# to be done: everything is handled internally.
stop_flags=(S -- --stop -S)

# the flag '-', usually instructing programs to read from stdin, is not
# special: declare it like any other (bare) flag and use it however you
# wish
read_stdin=(B -)


if ! zparse_flags flag_h flag_l flag_o stop_flags read_stdin \
                  inputs other_flags inputs_and_other_flags --- $@
then
	exit 1
fi


# deal with the 'read_stdin' flag ('-') ourselves, just as with any other
# (bare) flag:

if zparse_flags_has_flag read_stdin; then
	echo - "    + program should read from stdin"
fi


if zparse_flags_has_flag flag_h; then
	echo - "    + flag -h/--help was present"
fi

if zparse_flags_has_flag flag_l; then

	if ! log_file=$(zparse_flags_get_input flag_l); then
		echo - "    + flag -l/--log was present"
	else
		echo - "    + flag -l/--log was present with input: $log_file"
	fi
fi

if zparse_flags_has_flag flag_o; then
	echo - "    + flag -o/-O/--output present with input: $(zparse_flags_get_input flag_o)"
fi

if zparse_flags_has_flag inputs; then
	echo - "    + last input: $(zparse_flags_get_input inputs)"

	typeset -a all
	zparse_flags_get_all_inputs inputs all
	echo - "    + all non-flag arguments: $all"
fi

if zparse_flags_has_flag other_flags; then
	typeset -a all_other_flags
	zparse_flags_get_all_inputs other_flags all_other_flags
	echo - "    + all non-recognized flags: $all_other_flags"
fi

if zparse_flags_has_flag inputs_and_other_flags; then
	typeset -a all_together
	zparse_flags_get_all_inputs inputs_and_other_flags all_together
	echo - "    + all inputs and non-recognized flags: $all_together"
fi
```

Output:

```sh
$./test.zsh - -h
    + program should read from stdin
    + flag -h/--help was present

$ ./test.zsh -- - -h
    + last input: -h
    + all non-flag arguments: - -h
    + all non-recognized flags: - -h
    + all inputs and non-recognized flags: - -h

$ ./test.zsh -oA --stop -oB
    + flag -o/-O/--output present with input: A
    + last input: -oB
    + all non-flag arguments: -oB
    + all non-recognized flags: -oB
    + all inputs and non-recognized flags: -oB

$ ./test.zsh -h -S -l
    + flag -h/--help was present
    + last input: -l
    + all non-flag arguments: -l
    + all non-recognized flags: -l
    + all inputs and non-recognized flags: -l

$ ./test.zsh -hS -l
    + flag -h/--help was present
    + last input: -l
    + all non-flag arguments: -l
    + all non-recognized flags: -l
    + all inputs and non-recognized flags: -l

$ ./test.zsh -hSl
error: arg 1: flag ‘-h’: flag does not take an input: ‘Sl’.
```

### Example 6: Non-standard flags

Flags that begin with '-' are regarded as being *standard* flags. For such flags, those that begin with two dashes ('--') are classified as being *long* flags, and those that begin with only one dash ('-') are classified as being *short* flags. Short and long flags behave differently (e.g., concatenating flags and style for taking inputs); when declaring *non-standard* flags you must make explicit if the flag is long or short by prefixing the flag with 'l:' or 's:' respectively.

```sh
#!/bin/zsh
# file name: ./test.zsh

zparse_flags_req=0
source ~/.zsh/plugins/zparse_flags/zparse_flags

# Non-standard flags that should behave like '-x' must be prefixed with 's:'
# and non-standard flags that should behave like '--xflag' must be prefixed
# with 'l:'
#
# Note that when one flag is a substring of another (as 'h' is of 'help'), then
# the longer flag should be listed first, or else it will never be matched
# since the parsing code will always match the smaller flag and then stop.

flag_h=(B -h --help l:help s:h)      # place 'l:help' before 's:h'
flag_l=(O -l --log l:log s:l)        # place 'l:log' before 's:l'
flag_o=(M -o --output l:output s:o)  # place 'l:output' before 's:o'


if ! zparse_flags flag_h flag_l flag_o stop_flags read_stdin \
                  inputs other_flags inputs_and_other_flags --- $@
then
	exit 1
fi


# deal with the 'read_stdin' flag ('-') ourselves, just as with any other
# (bare) flag:
if zparse_flags_has_flag read_stdin; then
	echo - "    + program should read from stdin"
fi

if zparse_flags_has_flag flag_h; then
	echo - "    + flag -h/--help was present"
fi

if zparse_flags_has_flag flag_l; then

	if ! log_file=$(zparse_flags_get_input flag_l); then
		echo - "    + flag -l/--log was present"
	else
		echo - "    + flag -l/--log was present with input: $log_file"
	fi
fi

if zparse_flags_has_flag flag_o; then
	echo - "    + flag -o/-O/--output present with input: $(zparse_flags_get_input flag_o)"
fi
```

Output:

```sh
$ ./test.zsh -ho A
    + flag -h/--help was present
    + flag -o/-O/--output present with input: A

$ ./test.zsh ho A
    + flag -h/--help was present
    + flag -o/-O/--output present with input: A

$ ./test.zsh help log=file
    + flag -h/--help was present
    + flag -l/--log was present with input: file

$ ./test.zsh --help o file1 ofile2
    + flag -h/--help was present
    + flag -o/-O/--output present with input: file2
```

## Licence

GNU GPL v3+

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
