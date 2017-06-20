# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure("2") do |config|
  config.vm.define "zimbra8" do |zimbra8|
    zimbra8.vm.box = "bento/centos-7.3"
    zimbra8.vm.network 'private_network', ip: '192.168.80.81'
    zimbra8.vm.hostname = 'zimbra8.zboxapp.dev'
    zimbra8.vm.network 'forwarded_port', guest: 7071, host: 8071
    zimbra8.vm.network 'forwarded_port', guest: 443, host: 8443
    zimbra8.vm.provision "ansible" do |ansible|
      ansible.playbook = 'vagrant/provision/playbook.yml'
      ansible.sudo = true
    end
    zimbra8.vm.provider 'parallels' do |v|
      v.update_guest_tools = true
      v.memory = 2048
      v.cpus = 2
      v.linked_clone = true
    end
  end

  config.vm.define "zimbra6" do |zimbra6|
    zimbra6.vm.box = "bento/centos-5.11"
    zimbra6.vm.box_check_update = false
    zimbra6.vm.network 'private_network', ip: '192.168.80.61'
    zimbra6.vm.hostname = 'zimbra6.zboxapp.dev'
    zimbra6.vm.network 'forwarded_port', guest: 7071, host: 6071
    zimbra6.vm.network 'forwarded_port', guest: 443, host: 6443
    zimbra6.vm.provider 'parallels' do |v|
      v.memory = 2048
      v.cpus = 2
      v.linked_clone = true
    end
  end

  # config.vm.provision "shell", inline: <<-SHELL
  #   apt-get update
  #   apt-get install -y apache2
  # SHELL
end
