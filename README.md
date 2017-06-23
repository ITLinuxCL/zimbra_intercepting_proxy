# ZmProxy

This software is used to intercept and apply modifications to the traffic between a Zimbra Proxy and Zimbra Mailboxes. If you don't know what a Zimbra Proxy is, You can read about it here: [https://wiki.zimbra.com/wiki/Zimbra_Proxy_Guide](https://wiki.zimbra.com/wiki/Zimbra_Proxy_Guide)

This work for all kind of client access:

* POP3
* IMAP
* Webmail
* ActiveSync
* Zimbra Outlook Connector

## What this try to solve?

### Zimbra Migrations
Suppose you need to move a lot of users and data from one Zimbra Platform to another, like we do at [ZBox](http://www.zboxapp.com), and given the size of the migration, you can't move all the mailboxes at once, so you have to do it in groups.

This procedure have the following inconvenients:

* You have to update the configuration of the clients for all the migrated users,
* Your users will need to learn a new Webmail URL,
* It's not transparent for the end user,
* It's a lot of work for you

### Network and OpenSource Deployments
Not a hot topic for Zimbra Inc., sorry guys, but lets be honest about it, some companies can't afford Zimbra Network for all the employees, so they use two setup platform.

The main problem with this is that you have to configure your clients with to kind of information.

## Tutorial
This tutorial is based on the following setup:

* One Zimbra Mailbox v6, that we want to migrate to,
* Multi Server Zimbra, with 1 Zimbra Proxy, and 2 Zimbra Mailboxes

Also, the new Zimbra Proxy should be running on CentOS 7.

### 1. Install Docker on the Zimbra Proxy Server

```
$ yum install epel-release -y
$ yum install docker -y
$ systemctl enable docker
$ systemctl start docker
```

### 2. Configure Zimbra Nginx Templates
This config is going to use a running Docker listen on the `9090` port.

 ```
 # Backup directory
 $ cp -a /opt/zimbra/conf/nginx/templates /opt/zimbra/conf/nginx/templates.backup
 $ curl -k https://raw.githubusercontent.com/ITLinuxCL/zimbra_intercepting_proxy/master/examples/nginx.conf.mail.template > /opt/zimbra/conf/nginx/templates/nginx.conf.mail.template
 $ curl -k https://raw.githubusercontent.com/ITLinuxCL/zimbra_intercepting_proxy/master/examples/nginx.conf.web.template > /opt/zimbra/conf/nginx/templates/nginx.conf.web.template
 $ curl -k https://raw.githubusercontent.com/ITLinuxCL/zimbra_intercepting_proxy/master/examples/nginx.conf.zmlookup.template > /opt/zimbra/conf/nginx/templates/nginx.conf.zmlookup.template
 $ chown zimbra.zimbra -R /opt/zimbra/conf/nginx/templates/
 ```

### 3. Create and Admin User
We need an admin user to lookup the mailbox for the account, this admin needs to have a **non-expiring token**.

```
$ zmprov ca zmproxy@example.com Password \
  zimbraIsAdminAccount TRUE \
  zimbraAdminAuthTokenLifetime 100d \
  zimbraAuthTokenLifetime 100d
```

### 4. Start the Container

```
# Interactive Mode
$ docker run --rm -ti --dns=192.168.80.81 -p 9090:9090 \
  -e ZIMBRA_USER=zmproxy@example.com \
  -e ZIMBRA_PASSWORD=Password \
  -e NAMESERVERS=192.168.80.81 \
  -e ZIMBRA_SOAP=https://any_new_mailbox:7071/service/admin/soap \
  -e DEFAULT_MAILBOX_IP=192.168.80.81 \
  -e MAILBOXES_MAPPING='192.168.80.81:8080:7110:7143:true;192.168.80.61:80:110:143' \
  -e PREFIX_PATH=/zimbra \
  -e VERBOSE=true \
  itlinuxcl/zimbra_zip

# Background just change this line
$ docker run -d --name zimbra_zip --dns=192.168.80.81 -p 9090:9090 \
  ......
```

You can check de running docker in background with:

```
docker logs zimbra_zip -f
```

About the variables:

* `ZIMBRA_USER`, is the admin user,
* `ZIMBRA_PASSWORD`, password for the admin user,
* `NAMESERVERS`, an IP address of a DNS server that can resolv all mailboxes, including old and new,
* `ZIMBRA_SOAP`, url of a mailbox where to do the lookups,
* `DEFAULT_MAILBOX_IP`, one of the mailboxes on the new platform
* `PREFIX_PATH`, the Zimbra 6 use a prefix when sending requests,
* `MAILBOXES_MAPPING`, this holds the information of the port used in every mailbox.

The syntax of `MAILBOXES_MAPPING` is:

```
IP,WEB_P,POP_P,IMAP_P:REMOVE_PREFIX;IP,WEB_P,POP_P,IMAP_P:REMOVE_PREFIX;
```

Where:

* `IP`, ip of a mailbox
* `WEB_P,POP_P,IMAP_P`, ports where listen the webmail, pop3, and imap services
* `REMOVE_PREFIX`, it ZmProxy shoud remove the `/zimbra` prefix for this mailbox

You **must** list all the mailboxes here.

### 5. Re-configure Zimbra Proxy and restart

```
$ /opt/zimbra/libexec/zmproxyconfgen
$ /opt/zimbra/bin/zmproxyctl restart
```

### 6. Check status
If you run the container in Interactive mode, you should see the logs on your screen, if not
you can run the following command:

```
$ docker logs zimbra_zip -f
```


## Thanks

* To the Zimbra folks for a great product, and
* [@igrigorik](http://twitter.com/igrigorik) for [em-proxy](https://github.com/igrigorik/em-proxy)

## Contributing

1. Fork it ( https://github.com/pbruna/zimbra_intercepting_proxy/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
