# Cookbook Name:: antani
# Recipe:: gitosis

package 'python-setuptools'

user node[ :gitosis ][ :user ] do
  system true
  shell "/bin/bash"
  comment "gitosis repositories"
  home node[ :gitosis ][ :home ]
  supports :manage_home => true
end

directory node[ :gitosis ][ :home ] do
  mode "0750"
  owner node[ :gitosis ][ :user ]
  group node[ :gitosis ][ :user ]
end

file "#{ node[ :gitosis ][ :home ] }/.gitconfig" do
  mode "0640"
  owner node[ :gitosis ][ :user ]
  group node[ :gitosis ][ :user ]
  content <<EOF
[user]
    email = git@#{node[:fqdn]}
    name = Git
EOF
end

gitosis_source_path = "#{ node[ :gitosis ][ :home ] }/gitosis-source"

if not File.directory?( gitosis_source_path )

  git gitosis_source_path do
    repository "git://eagain.net/gitosis.git"
    user node[ :gitosis ][ :user ]
    group node[ :gitosis ][ :user ]
    action :sync
  end

  bash "Install gitosis" do
    cwd gitosis_source_path
    code "python setup.py install"
  end

end


RSA_KEY = "#{ node[ :gitosis ][ :home ] }/.ssh/id_git"

if not File.directory?( RSA_KEY )

  execute "ssh-keygen -t rsa -f #{ RSA_KEY } -N '' -C gitosis" do
    creates RSA_KEY
    cwd node[ :gitosis ][ :home ]
    user node[ :gitosis ][ :user ]
    group node[ :gitosis ][ :user ]
  end

  execute "gitosis-init < #{ RSA_KEY }.pub" do
    creates "#{ node[ :gitosis ][ :home ] }/.gitosis.conf"
    cwd node[ :gitosis ][ :home ]
    user node[ :gitosis ][ :user ]
    group node[ :gitosis ][ :user ]
    umask "027"
    environment "HOME" => node[ :gitosis ][ :home ]
  end

end


# Add user keys to gitosis
gitosis_admin_repo_path = "#{ node[ :gitosis ][ :home ] }/admin"

execute "git clone #{ node[ :gitosis ][ :home ] }/repositories/gitosis-admin.git admin" do
  user node[ :gitosis ][ :user ]
  group node[ :gitosis ][ :user ]
  environment "HOME" => node[ :gitosis ][ :home ]
  cwd node[ :gitosis ][ :home ]
  umask "027"
  not_if { File.directory? gitosis_admin_repo_path }
end

KEY_FILE  = '/root/antani_data_bag_key'
SECRET    = Chef::EncryptedDataBagItem.load_secret( KEY_FILE )
DATA_BAG  = Chef::EncryptedDataBagItem.load( 'users', 'all', SECRET )
ALL_USERS = DATA_BAG[ 'users' ]

directory "#{ node[ :gitosis ][ :home ] }/admin/keydir" do
  owner node[ :gitosis ][ :user ]
  group node[ :gitosis ][ :user ]
end

ALL_USERS.each do | u |
  file "#{ node[ :gitosis ][ :home ] }/admin/keydir/#{u['logon']}.pub" do
    content u['public-keys'].first
    owner node[ :gitosis ][ :user ]
    group node[ :gitosis ][ :user ]
  end  
end

template "#{ node[ :gitosis ][ :home ] }/admin/gitosis.conf" do
  owner node[ :gitosis ][ :user ]
  group node[ :gitosis ][ :user ]
  variables :users => ALL_USERS.collect { |u| u['logon'] }
end

bash "reconfigure gitosis" do
  code <<-EOF
    set -e -x
    git add keydir/*.pub gitosis.conf
    git commit -m 'reconfigure'
    git push
  EOF
  cwd gitosis_admin_repo_path
  user node[ :gitosis ][ :user ]
  group node[ :gitosis ][ :user ]
  environment "HOME" => node[ :gitosis ][ :home ]
  not_if "git status | grep -q '^nothing to commit'", :user  => node[ :gitosis ][ :user ],
                                                      :group => node[ :gitosis ][ :user ],
                                                      :cwd   => gitosis_admin_repo_path
end
