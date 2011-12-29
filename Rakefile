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
require 'json'

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
      encryped_data  = JSON.load( File.open( encrypted_file ) )
      secret         = Chef::EncryptedDataBagItem.load_secret( args.secret_key_file )
      puts Chef::EncryptedDataBagItem.new( encryped_data, secret ).to_hash
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
    cookbooks += [ 'antani', 'users', 'apache2' ,'passenger_apache2' ]
    cookbooks.uniq!
    cookbooks_match = cookbooks.join( '\|' )
    `find ./cookbooks ./data_bags \\( -regex '.*/\\(#{ cookbooks_match }\\)*/.*' -or -regex '^./data_bags/.*' \\) -print0 | tar zcv --null -f chef-solo.tar.gz -T -`
  end

end
