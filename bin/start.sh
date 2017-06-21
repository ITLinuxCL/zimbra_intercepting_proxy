#!/bin/bash
echo "nameserver $NAMESERVERS" > /etc/resolv.conf


ruby -I /usr/src/app/lib /usr/src/app/bin/zimbra_intercepting_proxy \
-z $ZIMBRA_USER \
-v $VERBOSE \
--nameservers $NAMESERVERS \
--url $ZIMBRA_SOAP \
--default-mailbox-ip $DEFAULT_MAILBOX_IP \
--mailboxes-mapping $MAILBOXES_MAPPING \
-P $ZIMBRA_PASSWORD
