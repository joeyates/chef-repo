########################
# nginx

if not File.directory?( '/opt/nginx' )

  bash 'compile passenger for Nginx' do
    user 'root'
    code <<-EOH
    passenger-install-nginx-module --auto-download --prefix=/opt/nginx --auto
    EOH
  end

  # see http://wiki.nginx.org/Nginx-init-ubuntu
  template '/etc/init.d/nginx' do
    source 'nginx/nginx.init.erb'
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

end
