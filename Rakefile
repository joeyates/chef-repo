#
# Rakefile for Chef Server Repository
#
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2008 Opscode, Inc.
# License:: Apache License, Version 2.0
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

require 'rubygems'
require 'chef'
require 'highline'
require 'json'
require 'remote/session'
require 'vagrant'

# Load constants from rake config file.
require File.join(File.dirname(__FILE__), 'config', 'rake')

# Detect the version control system and assign to $vcs. Used by the update
# task in chef_repo.rake (below). The install task calls update, so this
# is run whenever the repo is installed.
#
# Comment out these lines to skip the update.

if File.directory?(File.join(TOPDIR, ".svn"))
  $vcs = :svn
elsif File.directory?(File.join(TOPDIR, ".git"))
  $vcs = :git
end

# Load common, useful tasks from Chef.
# rake -T to see the tasks this loads.

load 'chef/tasks/chef_repo.rake'

desc "Bundle a single cookbook for distribution"
task :bundle_cookbook => [ :metadata ]
task :bundle_cookbook, :cookbook do |t, args|
  tarball_name = "#{args.cookbook}.tar.gz"
  temp_dir = File.join(Dir.tmpdir, "chef-upload-cookbooks")
  temp_cookbook_dir = File.join(temp_dir, args.cookbook)
  tarball_dir = File.join(TOPDIR, "pkgs")
  FileUtils.mkdir_p(tarball_dir)
  FileUtils.mkdir(temp_dir)
  FileUtils.mkdir(temp_cookbook_dir)

  child_folders = [ "cookbooks/#{args.cookbook}", "site-cookbooks/#{args.cookbook}" ]
  child_folders.each do |folder|
    file_path = File.join(TOPDIR, folder, ".")
    FileUtils.cp_r(file_path, temp_cookbook_dir) if File.directory?(file_path)
  end

  system("tar", "-C", temp_dir, "-cvzf", File.join(tarball_dir, tarball_name), "./#{args.cookbook}")

  FileUtils.rm_rf temp_dir
end

namespace :databag do

  namespace :encrypted do

    desc 'Save'
    task :save, [ :plain_json_file, :secret_key_file, :data_bag, :name ] do | t, args |
      plain_hash     = JSON.load( File.open( args.plain_json_file ) )
      secret         = Chef::EncryptedDataBagItem.load_secret( args.secret_key_file )
      encrypted      = Chef::EncryptedDataBagItem.encrypt_data_bag_item( plain_hash, secret)
      encrypted_path = File.join( 'data_bags', args.data_bag )
      FileUtils.mkdir_p( encrypted_path )
      encrypted_file = File.join( encrypted_path, args.name + '.json' )
      File.open( encrypted_file, 'wb' ) do | f |
        f.write encrypted.to_json
      end
    end

    desc 'Extract an encrypted data bag'
    task :extract, [ :data_bag, :name, :secret_key_file ] do | t, args |
      encrypted_file = File.join( 'data_bags', args.data_bag, args.name + '.json' )
      encrypted_data = JSON.load( File.open( encrypted_file ) )
      secret         = Chef::EncryptedDataBagItem.load_secret( File.expand_path args.secret_key_file )
      puts Chef::EncryptedDataBagItem.new( encrypted_data, secret ).to_hash.to_yaml
    end

  end

end

namespace :antani do

  desc 'Encrypt secrets'
  task :encrypt, [ :secret_key_file ] do | t, args |
    call_args = Rake::TaskArguments.new( [ :plain_json_file, :secret_key_file, :data_bag, :name ],
                                         [ 'all.json', args.secret_key_file, 'users', 'all' ] )
    Rake::Task[ 'databag:encrypted:save' ].execute( call_args )
  end

  desc 'Prepare the tarball'
  task :tarball, [ :cookbooks ] do | t, args |
    cookbooks = args.cookbooks || []
    cookbooks += [ 'antani' ]
    cookbooks.uniq!
    cookbooks_match = cookbooks.join( '\|' )
    `find ./cookbooks ./data_bags \\( -regex '.*/\\(#{ cookbooks_match }\\)*/.*' -or -regex '^./data_bags/.*' \\) -print0 | tar zcv --null -f chef-solo.tar.gz -T -`
  end

  desc 'Update the machine, running chef-solo'
  task :update => [ 'antani:load_session',
                    'antani:do_update',
                    'antani:close_session' ]

  task :do_update do
    @rs.sudo 'chef-solo -r https://github.com/joeyates/chef-repo/raw/master/chef-solo.tar.gz'
  end

  task :check_key do
    raise 'SECRET_KEY should indicate the path of the key used for decryption of data bags' if ENV[ 'SECRET_KEY' ].nil?
  end

  task :load_session do
    if ENV[ 'ANTANI_INSTALL_TEST' ]
      load_test_session
    else
      # TODO: load real session
    end
  end

  task :close_session do
    if ! @rs.nil?
      @rs.close
      @rs = nil
    end
  end

  namespace 'install' do

    desc 'Install on the target machine'
    task :full => [ 'antani:check_key',
                    'antani:load_session',
                    #'antani:install:setup',
                    'antani:update',
                    'antani:close_session' ]

    task :setup => [ 'antani:install:dependencies',
                     'antani:install:ruby_193',
                     'antani:install:chef',
                     'antani:install:chef_solo',
                     'antani:install:update' ]

    # Install dependencies
    task :dependencies do
      @rs.sudo 'apt-get update'
      @rs.sudo 'apt-get install -y build-essential'
      # ruby:
      @rs.sudo 'apt-get install -y libreadline5-dev libssl-dev libsqlite3-dev zlib1g-dev libyaml-dev curl'
    end

    # Install ruby 1.9.3
    task :ruby_193 do
      @rs.sudo 'mkdir /root/build'
      @rs.sudo 'sh -c "cd /root/build && curl -O -# http://ftp.ruby-lang.org/pub/ruby/1.9/ruby-1.9.3-p0.tar.gz"'
      @rs.sudo 'sh -c "cd /root/build && tar xf ruby-1.9.3-p0.tar.gz"'
      @rs.sudo 'sh -c "cd /root/build/ruby-1.9.3-p0 && ./configure --prefix=/usr"'
      @rs.sudo 'sh -c "cd /root/build/ruby-1.9.3-p0 && make"'
      @rs.sudo 'sh -c "cd /root/build/ruby-1.9.3-p0 && make install"'
      @rs.sudo 'rm -rf /root/build'
    end

    # Install chef
    task :chef do
      @rs.sudo_put( '/root/.gemrc' ) { gemrc }
      @rs.sudo 'gem install chef --no-rdoc --no-ri'
    end

    # Create configuration files for chef-solo runs
    task :chef_solo do
      @rs.sudo 'mkdir /etc/chef'
      @rs.sudo '/var/chef-solo'
      @rs.sudo_put( '/etc/chef/solo.rb' ) { etc_chef_solo_rb }
      @rs.sudo_put( '/etc/chef/antani.json' ) { etc_chef_antani_json }
      @rs.sudo_put( '/root/antani_data_bag_key' ) { File.read( ENV[ 'SECRET_KEY' ] ) }
      @rs.sudo 'chmod 0600 /root/antani_data_bag_key'
    end

    def load_test_session
      env         = Vagrant::Environment.new
      vm_config   = env.primary_vm.config
      username    = vm_config.ssh.username
      host        = vm_config.ssh.host
      port        = vm_config.vm.forwarded_ports[ 0 ][ :hostport ]
      private_key = env.default_private_key_path.to_path

      @rs         = Remote::Session.new( host, :port        => port,
                                               :username    => username,
                                               :private_key => private_key )
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

  end

end

