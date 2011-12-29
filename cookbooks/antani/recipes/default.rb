#
# Cookbook Name:: antani
# Recipe:: default
#
# Copyright 2011, Example Com
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

require 'pp'

key_file = '/root/antani_data_bag_key'
puts "#{__FILE__}:#{__LINE__}: %% key_file: #{key_file}"
secret = Chef::EncryptedDataBagItem.load_secret(key_file)
puts "#{__FILE__}:#{__LINE__}: %% secret: #{secret}"
data_bag = Chef::EncryptedDataBagItem.load("users", "all", secret)
pp passwords
all_users = data_bag['all']
pp all_users