require "yaml"
require "uuid"
require 'em-proxy'
require 'http/parser'
require 'cgi'
require 'ansi/code'
require 'stringio'
require "addressable/uri"
require "zimbra_intercepting_proxy/version"
require "zimbra_intercepting_proxy/user"
require "zimbra_intercepting_proxy/config"
require "zimbra_intercepting_proxy/backend"
require "zimbra_intercepting_proxy/request"
require "zimbra_intercepting_proxy/server"

module ZimbraInterceptingProxy
  
  ZimbraInterceptingProxy::Config.domain="ind.cl"
  ZimbraInterceptingProxy::Config.migrated_users_file="/Users/pbruna/Proyectos/RUBY/gems/zimbra_intercepting_proxy/test/fixtures/users.yml"
  ZimbraInterceptingProxy::Config.old_backend = "www.indmail.cl"
  ZimbraInterceptingProxy::Config.new_backend = "190.196.215.125"
  
  def self.start
    ZimbraInterceptingProxy::Server.run
  end
  
end
