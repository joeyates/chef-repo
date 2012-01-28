#
# Cookbook Name:: antani
# Recipe:: default
#
# Copyright 2011, Example Com
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# TODO

# /etc/default/locale
# locale-gen en_GB.UTF-8
# update-locale LANG=en_GB.UTF-8

# /etc/hosts
# 127.0.0.1 localhost.localdomain localhost antani antani.co.uk

########################
# users and authentication

# ruby-shadow is required for setting user passwords
gem_package 'ruby-shadow' do
  action :install
end

key_file  = '/root/antani_data_bag_key'
secret    = Chef::EncryptedDataBagItem.load_secret( key_file )
data_bag  = Chef::EncryptedDataBagItem.load( 'users', 'all', secret )
all_users = data_bag[ 'users' ]

all_users.each do | u |
  home_dir = "/home/#{ u[ 'logon' ] }"

  user u[ 'logon' ] do
    shell u[ 'shell' ]
    home home_dir
    password u[ 'password' ]
    supports :manage_home => true
    not_if "test -d #{ home_dir }"
  end

  directory "#{ home_dir }/.ssh" do
    owner u[ 'logon' ]
    group u[ 'logon' ]
    mode '0700'
  end

  template "#{ home_dir }/.ssh/authorized_keys" do
    source 'authorized_keys.erb'
    owner u[ 'logon' ]
    group u[ 'logon' ]
    mode '0600'
    variables :ssh_keys => u[ 'public-keys' ]
    not_if "test -f #{ home_dir }/.ssh/authorized_keys"
  end

end

sudo_users = all_users.map { | u | u[ 'logon' ] }
group 'sudo' do
  members sudo_users
  append true
end

execute 'stop password logon via SSH' do
  user 'root'
  command "sed -ie 's/#*Port 22/Port #{ node[ :antani ][ :ssh ][ :port ] }/g' /etc/ssh/sshd_config"
  command "sed -ie 's/#*PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config"
  command "sed -ie 's/#*PermitRootLogin yes/PermitRootLogin no/g' /etc/ssh/sshd_config"
  command 'service ssh restart'
  action :run
end

#######################
# System settings

template '/etc/hostname' do
  source 'hostname.erb'
  mode '0644'
end

# TODO: This is not working: use a test on `hostname`
execute 'set hostname' do
  command 'service hostname start'
  action :run
  not_if { File.exists?('/etc/hostname') && File.open('/etc/hostname').read =~ /^#{ node[ :antani ][ :hostname ] }$/ }
end

#######################
# repositories

apt_repository 'ppa-p-balazs' do
  uri 'http://ppa.launchpad.net/p-balazs/postgresql/ubuntu'
  distribution node['lsb']['codename']
  components ['main']
  keyserver 'keyserver.ubuntu.com'
  key 'B89FA6AA'
  action :add
end

#######################
# Various packages

%w( aptitude bash-completion emacs23-nox g++ git-core git-completion htop zsh ).each do | p |
  package p do
    action :install
  end
end

#######################
# postgresql and postgis

# Normal install runs initdb without setting the encoding

if not File.directory?( '/var/lib/postgresql/9.1' )

  package 'postgresql-9.1' do
    action :install
  end

  # Repair encoding
  execute 're-create template databases with UTF8 encoding' do
    user 'root'
    command <<-EOT
    pg_dropcluster --stop 9.1 main
    pg_createcluster --encoding=UTF8 --start 9.1 main
    EOT
  end

  [ 'postgresql-9.1-postgis', 'postgresql-server-dev-9.1' ].each do | p |
    package p do
      action :install
    end
  end

  execute 'create postgis_template' do
    user 'postgres'
    command <<-EOT
    createdb -E UTF8 -T template0 template_postgis
    psql -d template_postgis -f /usr/share/postgresql/9.1/contrib/postgis-1.5/postgis.sql
    psql -d template_postgis -f /usr/share/postgresql/9.1/contrib/postgis-1.5/spatial_ref_sys.sql
    psql -d template_postgis -c "UPDATE pg_database SET datistemplate = TRUE WHERE datname = 'template_postgis';"
    EOT
  end

  template '/etc/postgresql/9.1/main/pg_hba.conf' do
    source 'pg_hba.conf'
    mode '0644'
  end

  execute 'apply changes to postgresql permissions' do
    user 'root'
    command '/etc/init.d/postgresql restart'
    action :run
  end

end

########################
# apache

# TODO:
# ports.conf
# NameVirtualHost 92.60.123.214:80

%w( apache2-mpm-prefork apache2-prefork-dev ).each do | p |
  package p do
    action :install
  end
end

template '/etc/apache2/ports.conf' do
  source 'apache2/ports.conf.erb'
end

directory '/etc/apache2/sites-available' do
  owner 'root'
  group 'sudo'
  mode '0775'
end

directory '/etc/apache2/sites-enabled' do
  owner 'root'
  group 'sudo'
  mode '0775'
end

########################
# ruby on rails

%w( libcurl4-openssl-dev libxml2-dev ).each do | p |
  package p do
    action :install
  end
end

gem_package 'passenger' do
  action :install
  version '3.0.11'
end

gem_package 'bundler' do
  action :install
  options :prerelease => true
end

gem_package 'backup' do
  action :install
end

bash 'compile passenger for Apache' do
  not_if { File.exists?( '/usr/lib/ruby/gems/1.9.1/gems/passenger-3.0.11/ext/apache2/mod_passenger.so' ) }
  user 'root'
  code <<-EOH
  passenger-install-apache2-module --auto
  EOH
end

template '/etc/apache2/mods-available/passenger.load' do
  source 'apache2/passenger.load'
end

link '/etc/apache2/mods-enabled/passenger.load' do
  to '/etc/apache2/mods-available/passenger.load'
end

# restart apache

####
include_recipe "antani::gitosis"
include_recipe "antani::nginx"
