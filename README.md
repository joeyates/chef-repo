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
rake "databag:encrypted:extract[users,all,/PATH/TO/antani_data_bag_key]" > all.json
```

Encrypt:
```shell
rake "antani:encrypt[/Users/joe/antani_data_bag_key]"
git add data_bags/users/all.json
```

Commit
------

```shell
rake antani:tarball
git add chef-solo.tar.gz
git commit
```

Host Setup
==========

Setup public key authentication
-------------------------------

```shell
$ ssh root@antani.co.uk "mkdir -p /root/.ssh && chmod 0700 /root/.ssh"
$ ssh-copy-id -i PUBLIC_KEY root@antani.co.uk
```

Install ruby and chef-solo
--------------------------

This is done from you local machine, using Capistrano.

```shell
$ cap chef:bootstrap TARGET=$ANTANI SECRET_KEY=/PATH/TO/antani_data_bag_key
```

Test
====

Full:

````shell
$ rake antani:install:full SECRET_KEY=path/to/key
```
Update:

````shell
$ rake antani:update
```

Deploy
======

Remotely
--------

Full:

```shell
$ rake antani:install:full SECRET_KEY=path/to/key ANTANI_FULL_INSTALL=1
```

Update:

```shell
$ rake antani:update ANTANI_FULL_INSTALL=1
```

Locally
-------

```shell
sudo chef-solo -r https://github.com/joeyates/chef-repo/raw/master/chef-solo.tar.gz
```

Project Layout
==============

See the original README: https://raw.github.com/opscode/chef-repo/master/README.md

