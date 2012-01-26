
user 'git' do
  system true
  shell '/usr/bin/git-shell'
  comment 'shared git repositories'
  home node[ :git_shared ][ :home ]
  supports :manage_home => true
end

directory node[ :git_shared ][ :home ] do
  mode '0750'
  owner 'git'
  group 'git'
end

directory "#{ node[ :git_shared ][ :home ] }/repositories" do
  mode '0770'
  owner 'git'
  group 'git'
end

template '/usr/local/bin/git-create-shared' do
  source 'git-create-shared.erb'
  mode '0755'
end
