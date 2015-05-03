# -*- mode: ruby -*-
# vi: set ft=ruby :
#
# Rather than "vagrant ssh" try:
#    winrs -r:http://localhost:55985 -u:vagrant cmd

VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = "mwrock/Windows2012R2"
  config.vm.guest = :windows
  config.vm.communicator = "winrm"
  config.winrm.username = "vagrant"
  config.winrm.password = "vagrant"
  config.vm.network "forwarded_port", id: "http", guest: 80, host: 8080
  config.vm.network "forwarded_port", id: "rdp", guest: 3389, host: 33389

  config.vm.provider "virtualbox" do |v|
    v.gui = true
    v.memory = "1024"
  end

  config.vm.provision :shell, :path => "scripts/disable-windows-update.ps1"
  config.vm.provision :shell, :path => "scripts/install-chocolatey.ps1"
  config.vm.provision :shell, :inline =>
    "choco install sqlite sqlite.shell git strawberryperl --confirm"
  config.vm.provision :shell, :path => "scripts/install-iis-8.5.ps1"
  config.vm.provision :shell, :path => "scripts/install-perl-modules.ps1"
  config.vm.provision :shell, :path => "scripts/install-iis-bugzilla.ps1"
end
