require "zimbra_intercepting_proxy"
require 'ostruct'

require 'minitest/autorun'
require 'minitest/reporters' # requires the gem
require 'webmock/minitest'

Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new # spec-like progress

ZimbraInterceptingProxy::Config.soap_admin_url = 'https://localhost:8071/service/admin/soap'
ZimbraInterceptingProxy::Config.mail_host_attribute = 'zimbraMailHost'
ZimbraInterceptingProxy::Config.domain = "zboxapp.dev"
ZimbraInterceptingProxy::Config.name_servers = ['192.168.80.81']
ZimbraInterceptingProxy::Config.old_backend = "old-mailbox.example.com"
ZimbraInterceptingProxy::Config.new_backend = "new-mailbox.zboxapp.com"

def add_error_line
  f = File.open ZimbraInterceptingProxy::Config.migrated_users_file, "a"
  f.puts "juan :94949494-9494949-040404"
  f.close
end

def restore_map_file
  backup_file = "./test/fixtures/users.yml.org"
  FileUtils.cp(backup_file, ZimbraInterceptingProxy::Config.migrated_users_file)
  FileUtils.rm "./test/fixtures/users.yml.org"
end

def backup_map_file
  backup_file = "./test/fixtures/users.yml.org"
  FileUtils.cp(ZimbraInterceptingProxy::Config.migrated_users_file, backup_file)
end
