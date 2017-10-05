#!/bin/sh
ruby -I /usr/src/app/lib /usr/src/app/bin/zimbra_intercepting_proxy \
-z $ZIMBRA_USER \
-v $VERBOSE \
-d $DEFAULT_DOMAIN \
--nameservers $NAMESERVERS \
--url $ZIMBRA_SOAP \
--default-mailbox-ip $DEFAULT_MAILBOX_IP \
--mailboxes-mapping $MAILBOXES_MAPPING \
--prefix-path $PREFIX_PATH \
-P $ZIMBRA_PASSWORD > /dev/stdout
