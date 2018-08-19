
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
#		This library contains various routines helping send SMTP messages to the
#		designated mail server
#
# ------------------------------------------------------------------------------

#
# Import Cisco Tcl extensions
#

namespace import ::cisco::eem::*
namespace import ::cisco::lib::*

#
#	Function: mail
#
#	Input:
#		server -- DNS name or IP address of the SMTP server
#		from -- e-mail address of the sender
#		to -- e-mail address of the recepient
#		subject -- subject of the message
#		body -- body of the message
#
#	Output:
#		-none-
#
#	Description:
#		This function sends formatted e-mail message to the SMTP server
#

proc mail { server, from, to, subject, body } {
	if { ! $server || ! $from || ! $to } {
		action_syslog priority err msg "Missing SERVER or FROM or TO fields"
		exit 1
	}

	set msg [format "Mailservername: %s" "$server"]
	set msg [format "%s\nFrom: %s" "$msg" "$from"]
	set msg [format "%s\nTo: %s" "$msg" "$to"]
	set _email_cc ""
	set body [format "%s\nCc: %s" "$msg" ""]
	set body [format "%s\nSubject: %s\n" "$msg" "$subject"]
	set body [format "%s\n%s" "$msg" "$body"]

	if [catch {smtp_send_email $msg} result] {
		action_syslog priority err msg "smtp_send_email: $result"
	}

	action_syslog priority info msg "Mail from $from was sent to $to succesfully"
}
