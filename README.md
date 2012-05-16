Develop
=======

Checkout
--------

```shell
gem install chef
git clone git@github.com:joeyates/chef-repo.git
```

Databags
--------

Decrypt:

```shell
rake databag:encrypted:extract[users,all,'/PATH/TO/antani_data_bag_key'] > all.json
```

Encrypt:
```shell
rake antani:encrypt['/Users/joe/antani_data_bag_key']
git add data_bags/users/all.json
```

Commit
------

```shell
rake antani:tarball
git add chef-solo.tar.gz
git commit
```

Deploy
======

On host:
```shell
sudo chef-solo -r https://github.com/joeyates/chef-repo/raw/master/chef-solo.tar.gz
```

Project Layout
==============

See the original README: https://raw.github.com/opscode/chef-repo/master/README.md

