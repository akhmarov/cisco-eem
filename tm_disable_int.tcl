::cisco::eem::event_register_none tag e1 queue_priority low maxrun 20 nice 1
::cisco::eem::event_register_timer tag e2 cron name "start" cron_entry [if {[info exists _tm_disable_int_start]} {format $_tm_disable_int_start} else {format "0 0 * * *"}]
::cisco::eem::event_register_timer tag e3 cron name "end" cron_entry [if {[info exists _tm_disable_int_end]} {format $_tm_disable_int_end} else {format "0 8 * * *"}]
::cisco::eem::trigger {
	::cisco::eem::correlate event e1 or event e2 or event e3
}
::cisco::eem::description "Policy disables interfaces for selected period of time"

# ------------------------------------------------------------------------------
#
#	EEM :: Policy
#
#	Author:    Vladimir Akhmarov
#	Date:      April 2012
#	Version:   1.2
#	License:   Cisco-Style BSD
#	Requires:  EEM 3.0
#
#	Description:
#		This policy is used to automatically disabling selected interface for
#		a period of time. Time interval must be set in KRON's format. If there
#		is no configured time interval, the policy will select default values:
#		from 00:00 till 08:00 in (24-hour format).
#
#	Environment variables:
#		_tm_disable_int_name  (mandatory) -- Interface name to disable
#		_tm_disable_int_start (optional)  -- Start date and time of the interval
#		_tm_disable_int_end   (optional)  -- End date and time of the interval
#
#	Configuration commands:
#		-none-
#
#	Usage (disable IEEE 802.11 interface between 00:00 and 08:00):
#		ISR(config)#event manager environment _tm_disable_int_name Dot11Radio0
#		ISR(config)#event manager environment _tm_disable_int_start 0 0 * * *
#		ISR(config)#event manager environment _tm_disable_int_end 0 8 * * *
#		ISR(config)#event manager policy tm_disable_int.tcl type user
#
# ------------------------------------------------------------------------------

#
# Import Cisco Tcl extensions
#

namespace import ::cisco::eem::*
namespace import ::cisco::lib::*

#
#	Function: int_check
#
#	Input:
#		int_name -- Name of the interface
#
#	Output:
#		-none-
#
#	Description:
#		This function tries to figure out is there any configured interface with
#		selected name or not
#

proc int_check { int_name } {
	if { ! $int_name } {
		action_syslog priority err msg "Missing name of the interface"
		exit 1
	}

	set result [cli_run [list "show ip interface brief | include $int_name"]]

	if { $result == "" } {
		return 0
	}
	else {
		return 1
	}
}

#
#	Function: int_state
#
#	Input:
#		int_name -- Name of the interface
#		int_state -- Interface state
#
#	Output:
#		-none-
#
#	Description:
#		This function enables or disables interface with the name found in the
#		first argument. The appropriate action is determined from the second
#		argument
#

proc int_state { int_name, int_state} {
	if { ! $int_name } {
		action_syslog priority err msg "Missing name of the interface"
		exit 1
	}
	if { ! $int_state } {
		action_syslog priority err msg "Missing state of the interface"
		exit 1
	}

	switch $int_state {
		"up" {
			set action_str "up"
			set action "no shutdown"
		}
		"down" {
			set action_str "down"
			set action "no shutdown"
		}
		default {
			action_syslog priority err msg "Invalid state of the interface"
			exit 1
		}
		
	}

	action_syslog priority info msg "Bringing interface $int_name $action_str"

	lappend cmd "configure terminal"
	lappend cmd "interface $int_name"
	lappend cmd "$action"

	cli_run {cmd}
	unset cmd
}

# ------------------------------------------------------------------------------

#
# Check environment variables
#

if { ! [info exists _tm_disable_int_name] } {
	action_syslog priority err msg "Missing environment variable _tm_disable_int_name"
	exit 1
}
if { [int_check {$_tm_disable_int_name}] == 0 } {
	action_syslog priority err msg "Missing interface configured in environment variable _tm_disable_int_name"
	exit 1
}
if { $_tm_disable_int_start == $_tm_disable_int_end } {
	action_syslog priority err msg "Time range must be greater than zero"
	exit 1
}

#
# Query environment variables from EEM_EVENT_TIMER_CRON
#

array set arr_einfo [event_reqinfo]

if {$_cerrno != 0} {
	action_syslog priority err msg "Cannot get environment data"
	exit 1
}

#foreach var $arr_einfo
#{
#	puts "$var\n"
#}

#
# Change interface state
#

switch $arr_einfo(timer_name) {
	"{start}" { int_state $_tm_disable_int_name "down" }
	"{end}"   { int_state $_tm_disable_int_name "up" }
	default { action_syslog priority info msg "Interface $_tm_disable_int_name will be disabled at $_tm_disable_int_start and will be enabled again at $_tm_disable_int_end" }
}
