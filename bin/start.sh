#!/bin/bash
echo "nameserver $NAMESERVERS" > /etc/resolv.conf


ruby -I /usr/src/app/lib /usr/src/app/bin/zimbra_intercepting_proxy \
-z $ZIMBRA_USER \
-v $VERBOSE \
--nameservers $NAMESERVERS \
--url $ZIMBRA_SOAP \
--default-mailbox-ip $DEFAULT_MAILBOX_IP \
--mailboxes-webmail-port $MAILBOXES_WEBMAIL_PORT \
-P $ZIMBRA_PASSWORD
