::cisco::eem::event_register_none tag e1 queue_priority low maxrun 20 nice 1
::cisco::eem::event_register_ipsla tag e2 group_name "change_bras" operation_id 1
::cisco::eem::trigger {
        ::cisco::eem::correlate event e1 or event e2
}
::cisco::eem::description "Policy switches between the main and the backup BRAS"
# ------------------------------------------------------------------------------
#
#       EEM :: Policy
#
#       Author:    Vladimir Akhmarov
#       Date:      April 2012
#       Version:   1.2
#       License:   Cisco-Style BSD
#       Requires:  EEM 3.0
#
#       Description:
#               This policy detects occurance of the IP SLA condition and changes L2TP
#               BRAS accordingly to the current active one. So if there is an active
#               BRAS with IP address 85.21.0.255 the policy will switch it to the IP
#               address 85.21.0.254. And if the IP SLA condition occures again the policy
#               will change IP address back to 85.21.0.255.
#
#       Environment variables:
#               -none-
#
#       Configuration commands:
#               ISR(config)#ip sla 1
#               ISR(config-ip-sla)#icmp-echo 85.21.0.255 source-interface FastEthernet4
#               ISR(config-ip-sla)#frequency 30
#               ISR(config-ip-sla)#exit
#               ISR(config)#ip sla schedule 1 life forever start-time now
#               ISR(config)#ip sla reaction-configuration 1 react timeout threshold-type immediate action-type triggerOnly
#               ISR(config)#ip sla enable reaction-alerts
#               ISR(config)#event manager policy la_change_bras.tcl type user
#
# ------------------------------------------------------------------------------
#
# Import Cisco Tcl extensions
#
namespace import ::cisco::eem::*
namespace import ::cisco::lib::*
#
#       Function: get_gw
#
#       Input:
#               int_name -- Name of the interface
#
#       Output:
#               An IP address of the gateway of last resort
#
#       Description:
#               This function extracts IP address of the gateway of last resort for the
#               selected interface (found in the first argument). If the interface name
#               is not selected the address of the first gateway will be used
#
proc get_gw { int_name } {
        if { ! $int_name } {
                set result [cli_run [list "show ip route 0.0.0.0 0.0.0.0 | include , via"]]
        }
        else {
                set result [cli_run [list "show ip route 0.0.0.0 0.0.0.0 | include , via $int_name"]]
        }
        regexp { [0-9]+\.[0-9]+\.[0-9]+\.[0-9]+ } $result nexthop
        return $nexthop
}
#
#       Function: set_bras
#
#       Input:
#               ip_addr -- IP address of the new L2TP BRAS
#
#       Output:
#               -none-
#
#       Description:
#               This function instructs router to establish L2TP tunnel with select IP
#               address (found in the first argument). The gateway of last resort is
#               also changed to the new IP address
#
proc set_bras { ip_addr } {
        if { ! $ip_addr } {
                action_syslog priority err msg "Missing IP address of the BRAS"
                exit 1
        }
        action_syslog priority info msg "Setting L2TP BRAS IP to: $ip_addr"
        lappend cmd "configure terminal"
        lappend cmd "interface Virtual-PPP1"
        lappend cmd "pseudowire $ip_addr 1 pw-class PWCLASS_BEELINE_L2TP"
        lappend cmd "exit"
        lappend cmd "no ip route 0.0.0.0 0.0.0.0 Virtual-PPP1"
        lappend cmd "ip route 0.0.0.0 0.0.0.0 Virtual-PPP1 $ip_addr"
        cli_run {cmd}
        unset cmd
}
# ------------------------------------------------------------------------------
#
# Query environment variables from EEM_EVENT_TIMER_CRON
#
array set arr_einfo [event_reqinfo]
if {$_cerrno != 0} {
        action_syslog priority err msg "Cannot get environment data"
        exit 1
}
if { $arr_einfo(condition) == "cleared" } {
        action_syslog priority info msg "IP SLA condition cleared"
        exit 0
}
action_syslog priority info msg "IP SLA condition occuried, switching to another BRAS"
#
# Get default route and put gateway ip address to $ip_nexthop
#
set ip_nexthop [get_gw "Virtual-PPP1"]
#
# Change BRAS
#
switch $ip_nexthop {
        "85.21.0.255" { set_bras 85.21.0.254 }
        "85.21.0.254" { set_bras 85.21.0.255 }
        default { action_syslog priority err msg "Invalid IP address of the BRAS" }
}
