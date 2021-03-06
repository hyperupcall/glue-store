#!/usr/bin/env bash
set -eo pipefail
shopt -s extglob nullglob globstar

# @file lint.sh
# @brief This file lints the Glue store, checking for common mistakes or inaccuracies
# @description Everything is quite inefficient, but it works. It could work faster if
# more files were passed in per command (rather than using 'for' loop) and by
# testing ignored lint cases in constant time
# @exitcode 1 At least one lint error
# @exitcode 2 Discontinuity within lint code integer sequence

# TODO: ensure variables after util.get_config start with 'cfg'
# TODO: ensure get_key variables have same name as key or start with 'key' or 'member' or 'property', etc.
# TODO: ensure bootstrap.generated is always followed by a {, and same with unbootstrap.generated, but with a }
# TODO: ensure reply with $exitCode or $REPLY, ensure exitCode is initialized
# TODO: check that files in 'config' are actually called and used

util:is_ignored_line() {
	local lastMatchedLine="$1"
	local file="$2"

	# Ignore comments
	if [[ ${lastMatchedLine::1} == '#' ]]; then
		return 0
	fi

	local regex="# glue-linter-ignore"
	if [[ $lastMatchedLine =~ $regex ]]; then
		return 0
	fi

	# shellcheck disable=SC1007
	local currentIgnoreFile= currentIgnoreLine=
	local -i haveRead=0
	while IFS= read -r line; do
		haveRead=$((haveRead+1))

		if ((haveRead == 1)); then
			currentIgnoreFile="$line"
		fi

		if ((haveRead == 2)); then
			currentIgnoreLine="$line"
		fi

		if ((haveRead == 3)); then
			haveRead=$((0))

			if [[ $currentIgnoreFile == "$file" && $currentIgnoreLine == "$lastMatchedLine" ]]; then
				return 0
			fi
		fi
	done < "$ignoreFile"



	return 1
}

util:get_n() {
	if [ "${1::1}" = - ]; then
		lastMatched="$(tac "$2" | sed "${1/#-/}q;d")"
	else
		lastMatched="$(sed "$1q;d" "$2")"
	fi

	printf '%s' "$lastMatched"
}

util:print_lint() {
	exitCode=2

	# This assumes a particular transgression is per-line.
	# This makes things easier as grep will match line by line
	while IFS= read -r lastMatchedLine; do
		lastMatchedLine=$(sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' <<< "$lastMatchedLine")
		if util:is_ignored_line "$lastMatchedLine" "$file"; then
			continue
		fi

		local error="Error (code $1)"
		local line="Line"
		local message="Message"
		if [[ ! -v NO_COLOR && $TERM != dumb ]]; then
			printf -v error "\033[0;31m%s\033[0m" "$error"
			printf -v line "\033[1;33m%s\033[0m" "$line"
			printf -v message "\033[1;33m%s\033[0m" "$message"
		fi

		echo "$error: $file"
		echo "  -> $line: '$lastMatchedLine'"
		echo "  -> $message: '$2'"
		echo
	done <<< "$lastMatched"

}

# shellcheck disable=SC2016
main() {
	declare -gi exitCode=0
	declare -g lastMatched=
	declare -g file
	declare -gr ignoreFile="./scripts/lint-ignore"

	# Hack because not having extra lines at end of ignore fails parser
	# This simply ensures there are always three empty lines at the end
	# of the file
	IGNORE_FILE="$ignoreFile" perl -e "$(cat <<-"EOF"
	use warnings;
	use strict;
	open my $fh, '<', $ENV{'IGNORE_FILE'} or die "Can't open file $!";
	my $file_content = do { local $/; <$fh> };
	my $newstring = $file_content =~ s/\n*\Z/\n\n/gr;
	open(FH, '>', $ENV{'IGNORE_FILE'}) or die $!;
	print FH $newstring;
	close(FH);
	EOF
	)"

	for file in ./{actions,tasks,util}/?*.sh; do
		if lastMatched="$(grep -P "(?<!ensure\.)cd[ \t]+" "$file")"; then
			util:print_lint 112 "Use 'ensure.cd' instead of 'cd'"
		fi

		if lastMatched="$(grep -P "(?<!util\.)shopt[ \t]+" "$file")"; then
			util:print_lint 116 "Use 'util.shopt' instead of 'shopt'"
		fi
	done

	for file in ./{actions,tasks}/?*.sh; do
		if [ "$(util:get_n 1 "$file")" != "#!/usr/bin/env bash" ]; then
			util:print_lint 101 'First line must begin with proper shebang'
		fi

		if [ "$(util:get_n 2 "$file")" != 'eval "$GLUE_BOOTSTRAP"' ]; then
			util:print_lint 102 'Second line must have eval'
		fi

		if [ "$(util:get_n 3 "$file")" != 'bootstrap' ]; then
			util:print_lint 103 'Third line must have bootstrap'
		fi

		if [ "$(util:get_n -1 "$file")" != 'unbootstrap' ]; then
			util:print_lint 106 "Second to last line must have 'unbootstrap'"
		fi

		if lastMatched="$(grep -E "REPLY=(\"\"|'')?$" "$file")"; then
			util:print_lint 109 "Do not set REPLY to empty string. This is already done in bootstrap()"
		fi

		if lastMatched="$(grep "\(||\|&&\)" "$file")"; then
			util:print_lint 110 "Do not use '||' or '&&', as they they will not work as intended with 'set -e' enabled"
		fi

		if [ ! -x "$file" ]; then
			lastMatched=
			util:print_lint 115 "File not marked as executable"
		fi
	done

	for file in ./actions/?*.sh; do
		if [ "$(util:get_n 5 "$file")" != 'action() {' ]; then
			util:print_lint 104 "Fifth line in task file must have an 'action()' function"
		fi

		if [ "$(util:get_n -2 "$file")" != 'action "$@"' ]; then
			util:print_lint 107 "Third to last line must have 'action \"\$@\"'"
		fi

		if [ "$(util:get_n -4 "$file")" != '}' ]; then
			util:print_lint 111 "Fifth to last line must have '}'"
		fi
	done

	for file in ./tasks/?*.sh; do
		if [ "$(util:get_n 5 "$file")" != 'task() {' ]; then
			util:print_lint 105 "Fifth line in task file must have an 'task()' function"
		fi

		if [ "$(util:get_n -2 "$file")" != 'task "$@"' ]; then
			util:print_lint 108 "Third to last line must have 'task \"\$@\"'"
		fi
	done

	for file in ./util/?*.sh; do
		local currentFn=
		local -i count=0
		while IFS= read -r line; do
			if ((count == 0)); then
				if [[ $line =~ ^ensure\.(.*)\(\) ]]; then
					currentFn="ensure.${BASH_REMATCH[1]}"
					count=$((1))
				fi
			elif ((count == 1)); then
				local regex="local fn=['\"]?${currentFn}['\"]?"
				if ! [[ $line =~ $regex ]]; then
					lastMatched="$line"
					util:print_lint 113 "First line in function must correctly set 'fn' as the name of the function"
				fi
				count=$((2))
			elif ((count == 2)); then
				local regex="bootstrap.fn \"?\\$\"?"
				if ! [[ $line =~ $regex ]]; then
					lastMatched="$line"
					util:print_lint 114 "Second line in function must call 'bootstrap.fn' properly"
				fi
				count=$((0))
			fi
		done < "$file"
	done

	# Ensure no lint codes are skipped or repeated
	# Codes start at '101'
	local -i numCount=101
	# shellcheck disable=SC2013
	for num in $(grep -Eo 'util:print_lint 1[0-9]+' ./scripts/lint.sh | cut -d\  -f2 | sort -n); do
		if ((num != numCount)); then
			echo "Error: Abnormality in lint numbers around '$num'"
			echo "  -> Expected: $numCount; Received: $num"
			exitCode=3

			# Reset to known good number
			numCount=$((num))
		fi

		numCount=$((numCount+1))
	done
	echo "Latest Num: $num"

	return "$exitCode"
}

main "$@"
