########################
# Errbit
# https://github.com/errbit/errbit

errbit_repo = "git://github.com/errbit/errbit.git"
errbit_path = "#{ node[:webapps][:path] }/errbit"
hostname = "errbit.antani.co.uk"
domain = "antani.co.uk"

# system dependencies
%w( mongodb libxml2 libxml2-dev libxslt-dev libcurl4-openssl-dev ).each do | p |
  package p do
    action :install
  end
end

unless File.directory? errbit_path

  execute "git clone #{errbit_repo} #{errbit_path}"

  template "#{errbit_path}/config/mongoid.yml" do
    mode "0644"
    source 'errbit/mongoid.yml'
  end

  template "#{errbit_path}/config/config.yml" do
    mode "0644"
    source 'errbit/config.yml.erb'
    variables :hostname => hostname,
              :domain => domain,
              :errbit_path => errbit_path
  end

  # FIXME: Errbit bootstrap task won't start in production env
  template "#{errbit_path}/Rakefile" do
    mode "0644"
    source "errbit/Rakefile.fixed"
  end

  bash "setup rails app" do
    cwd errbit_path
    code <<-EOH
export RAILS_ENV=production
bundle install --deployment --without development test
bundle exec rake errbit:bootstrap
chmod -R a+w log
EOH
  end

  template "#{node[:nginx][:path]}/sites/errbit.conf" do
    source 'errbit/errbit.nginx.conf.erb'
    variables :errbit_path => "#{errbit_path}/public",
              :hostname => hostname
  end

  execute "service nginx restart"

end


cron "clear resolved errors" do
  command     "cd #{errbit_path} && RAILS_ENV=production bundle exec rake errbit:db:clear_resolved"
  hour        4
  minute      0
  action      :create
end
