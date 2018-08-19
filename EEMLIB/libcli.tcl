
# ------------------------------------------------------------------------------
#
#	EEM :: Library
#
#	Author:    Vladimir Akhmarov
#	Date:      April 2012
#	Version:   1.0
#	License:   Cisco-Style BSD
#	Requires:  EEM 3.0
#
#	Description:
#		...
#
# ------------------------------------------------------------------------------

#
# Import Cisco Tcl extensions
#

namespace import ::cisco::eem::*
namespace import ::cisco::lib::*

#
#
#

proc libcli_open {} {
	global arr_cli

	if [catch {cli_open} result] {
		error $result $errorInfo
	}
	else {
		array set arr_cli $result
	}

	if [catch {cli_exec $arr_cli(fd) "enable"} result] {
		error $result $errorInfo
	}

	if [catch {cli_exec $arr_cli(fd) "terminal length 0"} result] {
		error $result $errorInfo
	}

	return $arr_cli
}

#
#
#

proc libcli_exec { commands } {
	global arr_cli

	set output ""

	if [llength $commands] < 1 {
		return -code ok $output
    }

	foreach cmd $commands {
		if [catch {cli_exec $arr_cli(fd) $cmd} result] {
			error $result $errorInfo
		}

		append output $result
	}

	return $output
}

#
#
#

proc libcli_close {} {
	global arr_cli

	if [catch {cli_close $arr_cli(fd) $arr_cli(tty_id)} result] {
		error $result $errorInfo
	}
}

#
#
#

proc libcli_xmlexec { command } {
	global arr_cli

	if [catch {xml_pi_exec $arr_cli(fd) $command} result] {
		error $result $errorInfo
	}

	return $result
}

#
#
#

proc libcli_xmlexec_spec { command, specfile } {
	global arr_cli

	if [catch {xml_pi_exec $arr_cli(fd) $command $specfile} result] {
		error $result $errorInfo
	}

	return $result
}

#
#
#

proc libcli_xmlget { data, tags } {
	global arr_cli

	if [catch {xml_pi_parse $arr_cli(fd) $data $tags} result] {
		error $result $errorInfo
	}

	return $result
}
