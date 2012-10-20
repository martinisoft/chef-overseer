#
# Cookbook Name:: overseer
# Recipe:: default
#
# Copyright 2012, Aaron Kalin
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

# Open up Chef::Recipe to include Helpers
class Chef::Recipe
  include Overseer
end

bag = node['overseer']['data_bag_name']
Chef::Log.info("Accessing Overseer data from Data Bag: #{bag}")

data_bag_items = begin
  data_bag(bag)
rescue => ex
  Chef::Log.warn("Data bag #{bag} not found (#{ex}), so skipping")
  []
end

# array of application data hashes
apps = data_bag_items.map { |a| (data_bag_item(bag, a) || Hash.new).to_hash }
# select all apps in my cluster
apps = apps.select do |app|
  # is it tagged {appname}_node or does it have that role?
  tagged?("#{app['id']}_node") || node.role?("#{app['id']}_node")
end
# set defaults for apps
initialize_app_defaults(apps)
# deterministically sort the apps
apps.sort! { |x, y| x['id'] <=> y['id'] }

# array of all application users
app_users = apps.map { |a| a['user'] }.uniq

# create application users
user_hash = Hash.new
Array(app_users).sort.each do |user|
  user_hash[user] = create_app_user(user)

  create_app_user_foreman_templates   user_hash[user]
  create_app_user_runit_service       user_hash[user]
end
app_users = user_hash

# create application ports
Array(apps).each do |config|
  app_user = app_users[config['user']]

  install_rvm_environment   config, app_user
  create_app_dirs           config, app_user
  configure_app_environment config, app_user
  if node['overseer']['webserver']
    create_app_vhost config, app_user
  end
end
