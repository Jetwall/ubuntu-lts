#
# Cookbook Name:: packer
# Recipe:: default
#
# Copyright 2014, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

include_recipe 'apt'
include_recipe 'nginx'


# Set up nginx default config
directory '/var/www/nginx-default' do
  owner 'www-data'
  group 'www-data'
  mode '0755'
  recursive true
  action :create
end

file '/var/www/nginx-default/index.html' do
  owner 'www-data'
  group 'www-data'
  mode '0755'
  content 'Hello World from the AWS Pop-up Loft!'
  action :create
end

###
# /etc/modprobe.d Safe Defaults
# See https://github.com/18F/ubuntu/blob/master/hardening.md
###
cookbook_file "/etc/modprobe.d/18Fhardened.conf" do
  source "18Fhardened.conf"
  mode 0644
  owner "root"
  group "root"
end

###
# Boot settings
# See https://github.com/18F/ubuntu/blob/master/hardening.md
###
# Set permissions of /boot/grub/grub.cfg
file "/boot/grub/grub.cfg" do
  owner "root"
  group "root"
  mode "0600"
  action :create
end

# TODO - turn the encrypted password in to a variable
cookbook_file "/etc/grub.d/40_custom" do
  source "40_custom"
  mode 0755
  owner "root"
  group "root"
  notifies :run, 'execute[update-grub]', :immediately
end
execute 'update-grub' do
  command 'update-grub'
end

###
# Redirect protections
# See https://github.com/18F/ubuntu/blob/master/hardening.md#redirect-protections
###
icmp_settings = [
  "net.ipv4.conf.default.rp_filter=1",
  "net.ipv4.conf.all.rp_filter=1",
  "net.ipv4.conf.all.accept_redirects=0",
  "net.ipv6.conf.all.accept_redirects=0",
  "net.ipv4.conf.default.accept_redirects=0",
  "net.ipv6.conf.default.accept_redirects=0",
  "net.ipv4.conf.all.secure_redirects=0",
  "net.ipv4.conf.default.secure_redirects=0",  
  "net.ipv4.conf.all.send_redirects=0",
  "net.ipv4.conf.default.send_redirects=0",
  "net.ipv4.conf.all.accept_source_route=0",
  "net.ipv6.conf.all.accept_source_route=0",
  "net.ipv4.conf.default.accept_source_route=0",
  "net.ipv6.conf.default.accept_source_route=0",
  "net.ipv4.conf.all.log_martians=1",
  "net.ipv4.conf.default.log_martians=1"
]
cookbook_file "/etc/sysctl.conf" do
  source "sysctl.conf"
  mode 0644
  owner "root"
  group "root"
  notifies :run, 'execute[update-grub]', :immediately
end

icmp_settings.each do |icmp_setting|
  execute "update_#{icmp_setting}" do
    command "/sbin/sysctl -w #{icmp_setting}"
    notifies :run, 'execute[flush-sysctl]', :delayed
  end
end
execute 'flush-sysctl' do
  command '/sbin/sysctl -w net.ipv4.route.flush=1 && /sbin/sysctl -w net.ipv6.route.flush=1'
end