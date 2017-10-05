require "yaml"
require 'em-proxy'
require 'http/parser'
require "addressable/uri"
require 'logger'
require 'xmlsimple'
require 'json'
require "zimbra_intercepting_proxy/version"
require "zimbra_intercepting_proxy/user"
require "zimbra_intercepting_proxy/config"
require "zimbra_intercepting_proxy/backend"
require "zimbra_intercepting_proxy/request"
require "zimbra_intercepting_proxy/server"
require "zimbra_intercepting_proxy/debug"
require "zimbra_intercepting_proxy/connection"
require "zimbra_intercepting_proxy/zm_lookup"

module ZimbraInterceptingProxy

  def self.start(options)
    config!(options)
    set_token!

    ZimbraInterceptingProxy::Server.run
  end

  def self.set_token!
    unless ZimbraInterceptingProxy::Config.zimbra_admin_authtoken
      username = ZimbraInterceptingProxy::Config.admin_user
      password = ZimbraInterceptingProxy::Config.admin_password

      begin
        token = ZimbraInterceptingProxy::ZmLookup.login(username: username, password: password)
      rescue Errno::ECONNREFUSED => e
        ZimbraInterceptingProxy::Debug.logger [:zimbra_admin, "SOAP URL not responding"]
        ZimbraInterceptingProxy::Debug.logger [:zimbra_admin_stack, e.message]
      end
      raise "ZimbraInterceptingProxy::LoginError" unless token
    end
  end

  def self.config!(options)
    ZimbraInterceptingProxy::Config.admin_user = options[:admin_user]
    ZimbraInterceptingProxy::Config.admin_password = options[:admin_password]
    ZimbraInterceptingProxy::Config.bind_address = options[:bind_address]
    ZimbraInterceptingProxy::Config.bind_port = options[:bind_port]
    ZimbraInterceptingProxy::Config.bind_address = options[:bind_address]
    ZimbraInterceptingProxy::Config.bind_port = options[:bind_port]
    ZimbraInterceptingProxy::Config.debug = options[:debug]
    ZimbraInterceptingProxy::Config.default_mailbox_ip = options[:default_mailbox_ip]
    ZimbraInterceptingProxy::Config.mailboxes_mapping = options[:mailboxes_mapping]
    ZimbraInterceptingProxy::Config.default_domain = options[:default_domain]
    ZimbraInterceptingProxy::Config.mail_host_attribute = options[:mail_host_attribute]
    ZimbraInterceptingProxy::Config.name_servers = options[:name_servers]
    ZimbraInterceptingProxy::Config.prefix_path = options[:prefix_path]
    ZimbraInterceptingProxy::Config.soap_admin_url = options[:soap_admin_url]
    ZimbraInterceptingProxy::Config.zimbra_admin_authtoken = options[:zimbra_admin_authtoken]
  end

end
