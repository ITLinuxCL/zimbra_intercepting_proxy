# Zimbra Intercepting Proxy

This software is used to intercept and apply modifications to the traffic between a Zimbra Proxy and Zimbra Mailboxes.
If you don't know what a Zimbra Proxy is, You can read about it here: [https://wiki.zimbra.com/wiki/Zimbra_Proxy_Guide](https://wiki.zimbra.com/wiki/Zimbra_Proxy_Guide)

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

### How Zimbra Intercepting Proxy Works
Zimbra Intercepting Proxy reads a map file, a `YAML` file, in which you indicate the pair `username:zimbraID` of the users located on the _other_  Mailbox.

Based on this information, `ZIP` tell the Zimbra Proxy to which Mailbox it should communicate with.

## Instalation and configuration

### Requirements
This has been tested with:

* Zimbra >= 7
* Ruby >= 2.0
* Zimbra Proxy

**You need to have direct access to the `7072` port of both Mailboxes**.

### Installation
It's recommended to install it on the same Zimbra Proxy server. All you need to do is run:

```bash
$ gem install zimbra_intercepting_proxy
```

### Zimbra Proxy Modification

**Important Note**
You are going to modify Zimbra template files, used to build the configuration files of Nginx. **Take some backups!!**

* All the files are located in `/opt/zimbra/conf/nginx/templates`.
* `<`, config being replaced
* `>`, new config

You have to make this modifications

```diff
 # nginx.conf.mail.template
19c19,20
<     ${mail.:auth_http}
---
>
>     auth_http  localhost:9072/service/extension/nginx-lookup;
```

```diff
 # nginx.conf.web.template
17c17
<         #${web.upstream.:servers}
---
>         server localhost:9080;
23c23
<     #${web.:routehandlers}
---
>     zmroutehandlers localhost:9072/service/extension/nginx-lookup;
```

Next restart. You should restart memcached and nginx, but just to be sure:

```bash
$ zmcontrol restart
```

### Starting Zimbra Intercepting Proxy

You have to start 2 instances of `ZIP`:

* One on port `9080` for Web and SOAP Auth Requests, and
* One on port `9072` for `Route-Handler`, this is how the Proxy knows to which Mailbox redirect the traffic.

So the first one:

```bash
$ zimbra_intercepting_proxy -d example.com -f /root/users.yml -o oldmailbox.example.com --newmailbox=190.196.215.125 -b 9080 --newmailboxlocalip=192.168.0.
```

And the second one:

```bash
$ zimbra_intercepting_proxy -d example.com -f /root/users.yml -o oldmailbox.example.com --newmailbox=190.196.215.125 -b 9072 --newmailboxlocalip=192.168.0.
```

#### Options

* `-d`, the domain, in case the user only enters the username,
* `-o`, the _default_ or old Mailbox,
* `--newmailbox`, the _other_ or new Mailbox,
* `-f`, the `YAML` map file, with the list of users on the `--newmailbox`,
* `-b`, the bind port
* `--newmailboxlocalip`, the LAN IP address of the `--newmailbox`


#### The Map File

It's a simple YAML file with a `email:zimbraId` pair, like

```yaml
max@example.com: "7b562c60-be97-0132-9a66-482a1423458f"
moliery@example.com: "7b562ce0-be97-0132-9a66-482a1423458f"
watson@example.com: "251b1902-2250-4477-bdd1-8a101f7e7e4e"
sherlock@example.com: "7b562dd0-be97-0132-9a66-482a1423458f"
```

Updating the file does **not require** a restart.

You can get the `zimbraId` with:

```
$ zmprov ga watson@example.com zimbraId
```

##### Error in Map File
If you have an error in your file, `ZIP` will return the on memory Map, this way we can keep the service up. In this event you should see this on `STDOUT`:

```shel
ERROR Yaml File: (./test/fixtures/users.yml): could not find expected ':' while scanning a simple key at line 7
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
