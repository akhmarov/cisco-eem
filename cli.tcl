
# ------------------------------------------------------------------------------
#
#	EEM LIBRARY
#
#	Author:    Vladimir Akhmarov
#	Date:      April 2012
#	Version:   1.0
#
#	Requires:  EEM 3.2
#	License:   Cisco-Style BSD
#
#	Description:
#		1
#
# ------------------------------------------------------------------------------

namespace import ::cisco::eem::*
namespace import ::cisco::lib::*

#
# Open CLI session
#

proc ios_cli_open { } {
	uplevel #0 {
		if { [array exists cli] } {
			return
		}

		if [catch {cli_open} result] {
			error $result $errorInfo
		} else {
			array set cli $result
		}
	}
}

#
# Close CLI session
#

proc ios_cli_close {} {
	if [catch {cli_close $cli(fd) $cli(tty_id)} result] {
		error $result $errorInfo
	}
}

#
# Exec CLI commands
#

proc ios_cli_exec { arr_cmd } {
	if [catch {cli_open} result] {
		error $result $errorInfo
	} else {
		array set cli $result
	}
	if [catch {cli_exec $cli(fd) "enable"} result] {
		error $result $errorInfo
	}
	if [catch {cli_exec $cli(fd) "terminal length 0"} result] {
		error $result $errorInfo
	}

	foreach cmd $arr_cmd {
		if [catch {cli_exec $cli(fd) $cmd} result] {
			error $result $errorInfo
		} else {
			set str [string length $cmd]
			while { $str > 0 } {
				incr str -1
				append line =
			}
			lappend cmd_output $line $cmd $line
			lappend cmd_output $result
		}
	}

	if [catch {cli_close $cli(fd) $cli(tty_id)} result] {
		error $result $errorInfo
	}

	return $cmd_output
}
