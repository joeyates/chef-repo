=begin

1. Setup public key authentication

 $ ssh root@antani.co.uk "mkdir -p /root/.ssh && chmod 0700 /root/.ssh"
 $ ssh-copy-id -i PUBLIC_KEY root@antani.co.uk

2. Install ruby and chef-solo

 $ cap chef:bootstrap TARGET=$ANTANI SECRET_KEY=/PATH/TO/antani_data_bag_key

3. Run chef-solo

 $ cap chef:run_recipes TARGET=$ANTANI

=end

role :target,   ENV[ 'TARGET' ] || 'antani.co.uk'
set  :user,     'root'

namespace :chef do

  desc 'Install minimal setup on remote machine'
  task :bootstrap, :roles => :target do
    raise "SECRET_KEY not set" unless ENV[ 'SECRET_KEY' ]
    raise "SECRET_KEY file does not exist" unless File.exist?( ENV[ 'SECRET_KEY' ] )
    install_dependencies
    ruby193
    gems
    install_chef_solo
  end

  desc 'Run chef-solo'
  task :run_recipes, :roles => :target do
    run 'chef-solo -r https://github.com/joeyates/chef-repo/raw/master/chef-solo.tar.gz'
  end

  task :install_dependencies do
    run "apt-get update"
    run "apt-get install -y libreadline5-dev libssl-dev libsqlite3-dev zlib1g-dev libyaml-dev curl"
  end

  task :ruby193 do
    directory '/root/build'
    run 'cd /root/build && curl -O -# http://ftp.ruby-lang.org/pub/ruby/1.9/ruby-1.9.3-p0.tar.gz'
    run 'cd /root/build && tar xf ruby-1.9.3-p0.tar.gz'
    run 'cd /root/build/ruby-1.9.3-p0 && ./configure --prefix=/usr'
    run 'cd /root/build/ruby-1.9.3-p0 && make'
    run 'cd /root/build/ruby-1.9.3-p0 && make install'
    run 'rm -rf /root/build'
  end

  task :gems do
    put gemrc, '/root/.gemrc'
    run 'gem install chef'
  end

  task :install_chef_solo do
    directory '/etc/chef'
    directory '/var/chef-solo'
    put etc_chef_solo_rb, '/etc/chef/solo.rb'
    put etc_chef_antani_json, '/etc/chef/antani.json'
    put File.read( ENV[ 'SECRET_KEY' ] ), '/root/antani_data_bag_key'
    run 'chmod 0600 /root/antani_data_bag_key'
  end

end

def directory( path )
  run "mkdir -p #{ path }"
end

def gemrc
  <<-EOT
search:  --remote
install: --no-rdoc --no-ri
  EOT
end

def etc_chef_solo_rb
  <<-EOT
file_cache_path "/var/chef-solo"
cookbook_path "/var/chef-solo/cookbooks"
data_bag_path "/var/chef-solo/data_bags"
json_attribs "/etc/chef/antani.json"
recipe_url "https://github.com/joeyates/chef-repo/raw/master/chef-solo.tar.gz"
  EOT
end

def etc_chef_antani_json
  <<-EOT
{
 "name": "antani",
 "description": "Antani VPS",
 "run_list": [ "recipe[antani]" ]
}
  EOT
end
