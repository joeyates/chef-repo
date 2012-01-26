bash 'compile passenger for Nginx' do
  not_if { File.exists?( '/opt/nginx' ) }
  user 'root'
  code <<-EOH
  passenger-install-nginx-module --auto-download --prefix=/opt/nginx --auto
  EOH
end

#  http {
#      ...
#      passenger_root /usr/lib/ruby/gems/1.9.1/gems/passenger-3.0.11;
#      passenger_ruby /usr/bin/ruby;
#      ...
#  }

template '/etc/init.d/nginx' do
  source 'nginx.init.erb'
  mode '0755'
end

bash 'set init links' do
  user 'root'
  code "update-rc.d -f nginx defaults"
end

execute 'setup listening IP' do
  user 'root'
  command "sed -ie 's/\\([ ]*listen[ ]*\\)80;/\\1 #{ node[ :nginx ][ :ip ] }:80;/' /opt/nginx/conf/nginx.conf"
  action :run
end

bash 'start server' do
  user 'root'
  code "/etc/init.d/nginx start"
end
