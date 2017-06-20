require "yaml"
require "uuid"
require 'em-proxy'
require 'http/parser'
require "addressable/uri"
require 'logger'
require 'xmlsimple'
require 'erb'
require 'json'
require "zimbra_intercepting_proxy/version"
require "zimbra_intercepting_proxy/user"
require "zimbra_intercepting_proxy/config"
require "zimbra_intercepting_proxy/backend"
require "zimbra_intercepting_proxy/request"
require "zimbra_intercepting_proxy/server"
require "zimbra_intercepting_proxy/debug"
require "zimbra_intercepting_proxy/connection"
require "zimbra_intercepting_proxy/yamler"
require "zimbra_intercepting_proxy/zm_lookup"

module ZimbraInterceptingProxy

  def self.start(options)
    config!(options)
    ZimbraInterceptingProxy::Server.run
  end

  def self.config!(options)
    ZimbraInterceptingProxy::Config.domain = options[:domain]
    ZimbraInterceptingProxy::Config.migrated_users_file = options[:migrated_users_file]
    ZimbraInterceptingProxy::Config.old_backend = options[:old_backend]
    ZimbraInterceptingProxy::Config.new_backend = options[:new_backend]
    ZimbraInterceptingProxy::Config.bind_address = options[:bind_address] || "0.0.0.0"
    ZimbraInterceptingProxy::Config.bind_port = options[:bind_port]
    ZimbraInterceptingProxy::Config.debug = options[:debug]
    ZimbraInterceptingProxy::Config.new_mbx_local_ip_regex = options[:new_mbx_local_ip_regex]
  end

end
