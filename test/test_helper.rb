require "zm_proxy"
require 'ostruct'

require 'minitest/autorun'
require 'minitest/reporters' # requires the gem
require 'webmock/minitest'

Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new # spec-like progress

ZmProxy::Config.soap_admin_url = 'https://localhost:8071/service/admin/soap'
ZmProxy::Config.mail_host_attribute = 'zimbraMailHost'
ZmProxy::Config.domain = "zboxapp.dev"
ZmProxy::Config.name_servers = ['192.168.80.81']
ZmProxy::Config.migrated_users_file="./test/fixtures/users.yml"
ZmProxy::Config.old_backend = "old-mailbox.example.com"
ZmProxy::Config.new_backend = "new-mailbox.zboxapp.com"

def add_error_line
  f = File.open ZmProxy::Config.migrated_users_file, "a"
  f.puts "juan :94949494-9494949-040404"
  f.close
end

def restore_map_file
  backup_file = "./test/fixtures/users.yml.org"
  FileUtils.cp(backup_file, ZmProxy::Config.migrated_users_file)
  FileUtils.rm "./test/fixtures/users.yml.org"
end

def backup_map_file
  backup_file = "./test/fixtures/users.yml.org"
  FileUtils.cp(ZmProxy::Config.migrated_users_file, backup_file)
end
