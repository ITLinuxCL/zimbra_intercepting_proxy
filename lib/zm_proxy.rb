require "yaml"
require "uuid"
require 'em-proxy'
require 'http/parser'
require "addressable/uri"
require 'logger'
require 'xmlsimple'
require 'json'
require "zm_proxy/version"
require "zm_proxy/user"
require "zm_proxy/config"
require "zm_proxy/backend"
require "zm_proxy/request"
require "zm_proxy/server"
require "zm_proxy/logger"
require "zm_proxy/connection"
require "zm_proxy/zm_lookup"

module ZmProxy

  def self.start(options)
    config!(options)
    set_token!

    ZmProxy::Server.run
  end

  def self.set_token!
    unless ZmProxy::Config.zimbra_admin_authtoken
      username = ZmProxy::Config.admin_user
      password = ZmProxy::Config.admin_password

      token = ZmProxy::ZmLookup.login(username: username, password: password)
      raise "ZmProxy::LoginError - Check log" unless token
    end
  end

  def self.config!(options)
    ZmProxy::Config.admin_user = options[:admin_user]
    ZmProxy::Config.admin_password = options[:admin_password]
    ZmProxy::Config.bind_address = options[:bind_address]
    ZmProxy::Config.bind_port = options[:bind_port]
    ZmProxy::Config.bind_address = options[:bind_address]
    ZmProxy::Config.bind_port = options[:bind_port]
    ZmProxy::Config.debug = options[:debug]
    ZmProxy::Config.default_mailbox_ip = options[:default_mailbox_ip]
    ZmProxy::Config.mailboxes_mapping = options[:mailboxes_mapping]
    ZmProxy::Config.domain = options[:domain]
    ZmProxy::Config.mail_host_attribute = options[:mail_host_attribute]
    ZmProxy::Config.name_servers = options[:name_servers]
    ZmProxy::Config.prefix_path = options[:prefix_path]
    ZmProxy::Config.soap_admin_url = options[:soap_admin_url]
    ZmProxy::Config.zimbra_admin_authtoken = options[:zimbra_admin_authtoken]
  end

  def self.cfg
    return ZmProxy::Config
  end

  def self.Log
    return @@Logger if @@Logger
    @@Logger = ZmProxy::Logger.new
    @@Logger
  end
end
