########################
# apache

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
