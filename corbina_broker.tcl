::cisco::eem::event_register_ipsla operation_id 1

namespace import ::cisco::eem::
namespace import ::cisco::lib::

# getting EEM environment data
array set evtData [event_reqinfo]
set evt_cond $evtData(condition)

if { $evt_cond == "Cleared" }
{
	action_syslog msg "IP SLA condition cleared"
	exit 0
}

action_syslog msg "IP SLA condition occuried, establishing connection through another VPN broker"

if { [catch {cli_open} result] }
{
	puts stderr "CLI open failed ($result)"
	exit 0
}

array set cfd $result

# Get default route and put gateway ip address to $ip_nexthop
catch { cli_exec $cfd(fd) "show ip route 0.0.0.0 0.0.0.0 | include Virtual-PPP1" } result
regexp { [0-9]+\.[0-9]+\.[0-9]+\.[0-9]+ } $result ip_nexthop

cli_exec $cfd(fd) "enable"
cli_exec $cfd(fd) "configure terminal"
cli_exec $cfd(fd) "no ip route 0.0.0.0 0.0.0.0"

switch $ip_nexthop {
	85.21.0.255 {
		cli_exec $cfd(fd) "interface Virtual-PPP1"
		cli_exec $cfd(fd) "pseudowire 85.21.0.254 1 pw-class PSEUDOWIRE_CLASS_CORBINA_L2TP_V2"
		cli_exec $cfd(fd) "exit"
		cli_exec $cfd(fd) "ip access-list extended ACL_CORBINA_NAT"
		cli_exec $cfd(fd) "no 10"
		cli_exec $cfd(fd) "10 deny ip any host 85.21.0.254"
		cli_exec $cfd(fd) "exit"
		cli_exec $cfd(fd) "ip route 0.0.0.0 0.0.0.0 Virtual-PPP1 85.21.0.254"
	}
	85.21.0.254 {
		cli_exec $cfd(fd) "interface Virtual-PPP1"
		cli_exec $cfd(fd) "pseudowire 85.21.0.255 1 pw-class PSEUDOWIRE_CLASS_CORBINA_L2TP_V2"
		cli_exec $cfd(fd) "exit"
		cli_exec $cfd(fd) "ip access-list extended ACL_CORBINA_NAT"
		cli_exec $cfd(fd) "no 10"
		cli_exec $cfd(fd) "10 deny ip any host 85.21.0.255"
		cli_exec $cfd(fd) "exit"
		cli_exec $cfd(fd) "ip route 0.0.0.0 0.0.0.0 Virtual-PPP1 85.21.0.255"
	}
}

cli_exec $cfd(fd) "end"

catch {cli_close $cfd(fd) $cfd(tty_id)}
exit 0
