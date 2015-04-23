require "zimbra_intercepting_proxy"
require 'ostruct'

require 'minitest/autorun'
require 'minitest/reporters' # requires the gem

Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new # spec-like progress

ZimbraInterceptingProxy::Config.domain="example.com"
ZimbraInterceptingProxy::Config.migrated_users_file="./test/fixtures/users.yml"
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