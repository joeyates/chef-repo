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

execute '/etc/init.d/apache2 restart'
