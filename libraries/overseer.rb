# Cookbook Name:: overseer
# Library:: Chef::Overseer
#
# Author:: Aaron Kalin <akalin@martinisoftware.com>
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

module Overseer
  # Public: Setup application default settings
  #
  # apps - data bag hash of applications to be setup
  #
  # Sets up app data
  def initialize_app_defaults(apps)
    http_port = node['overseer']['first_http_port']

    apps.each do |app|
      app['user']                ||= app['id']
      app['name']                ||= app['id']
      app['env']                 ||= Hash.new
      app['http']                ||= Hash.new
      app['http']['host_name']   ||= "_"
      app['http']['http_port']   ||= 80
      app['http']['https_port']  ||= 443

      app['http']['ssl_certificate']      ||= "#{app['name']}.crt"
      app['http']['ssl_certificate_key']  ||= "#{app['name']}.key"

      deploy_to = "#{node['overseer']['root_path']}/#{app['name']}"
      app['http']['upstream_server'] ||=
      "unix:#{deploy_to}/shared/sockets/unicorn.sock"

      app['vhost_template'] ||= "overseer::nginx_vhost.conf.erb"

      if app['env']['PORT'].nil?
        app['env']['PORT'] = http_port.to_s
        http_port += 100
      end

      if app['env']['RAILS_ENV'].nil?
        app['env']['RAILS_ENV'] = "production"
      end
    end
  end

  def install_rvm_environment(app, user)
    include_recipe 'rvm'

    version = node['rvm']['version']
    branch  = node['rvm']['branch']
    rvmrc   = {
      'rvm_install_on_use_flag'       => 1,
      'rvm_gemset_create_on_use_flag' => 1,
      'rvm_trust_rvmrcs_flag'         => 1
    }

    script_flags      = build_script_flags(version, branch)
    installer_url     = node['rvm']['installer_url']
    rvm_prefix        = "#{node['overseer']['root_path']}/#{app['name']}"
    rvm_gem_options   = node['rvm']['rvm_gem_options']

    rvmrc_template  rvm_prefix: rvm_prefix,
                    rvm_gem_options: rvm_gem_options,
                    rvmrc: rvmrc,
                    user: app['name']

    install_rvm     rvm_prefix: rvm_prefix,
                    installer_url: installer_url,
                    script_flags: script_flags,
                    user: app['name']

    # Reset permissions on the rvmrc file
    file "#{rvm_prefix}/.rvm/.rvmrc" do
      group app['name']
    end

  end

  def create_app_user(user)
    user_home = "#{node['overseer']['root_path']}/#{user}"

    user_account user do
      home user_home
      system_user false
      manage_home true
      create_group true
      action :create
    end

    { 'id' => user, 'gid' => user, 'home' => user_home }
  end

  def create_app_user_foreman_templates(user)
    directory "#{user['home']}/.foreman/templates" do
      owner       user['id']
      group       user['gid']
      mode        "2755"
      recursive   true
    end

    directory "#{user['home']}/.foreman/templates/log" do
      owner       user['id']
      group       user['gid']
      mode        "2755"
      recursive   true
    end

    cookbook_file "#{user['home']}/.foreman/templates/run.erb" do
      source  "foreman/runit/run.erb"
      owner   user['id']
      group   user['gid']
      mode    "0644"
    end

    cookbook_file "#{user['home']}/.foreman/templates/log/run.erb" do
      source  "foreman/runit/log/run.erb"
      owner   user['id']
      group   user['gid']
      mode    "0644"
    end
  end

  def create_app_user_runit_service(user)
    directory "#{user['home']}/service" do
      owner       user['id']
      group       user['gid']
      mode        "2755"
      recursive   true
    end

    directory "/var/log/user-#{user['id']}" do
      owner       "root"
      group       "root"
      mode        "755"
      recursive   true
    end

    runit_service "user-#{user['id']}" do
      template_name   "user"
      options({ user: user['id'] })
    end
  end

  def create_app_dirs(config, user)
    root_path = node['overseer']['root_path']
    app_home  = "#{root_path}/#{config['name']}"

    directory root_path

    app_dirs = [
      app_home,
      "#{app_home}/shared",
      "#{app_home}/shared/config",
      "#{app_home}/shared/sv",
      "#{app_home}/shared/sessions",
      "#{app_home}/shared/sockets",
      "#{app_home}/shared/pids"
    ]

    app_dirs.each do |dir|
      directory dir do
        owner       user['id']
        group       user['gid']
        mode        "2775"
        recursive   true
      end
    end
  end

  def configure_app_environment(config, user)
    root_path = node['overseer']['root_path']
    app_home  = "#{root_path}/#{config['name']}"

    template "#{app_home}/shared/env" do
      source  "env.erb"
      owner   user['id']
      group   user['gid']
      mode    "0664"
      variables({ config: config })
    end

    if config['ssh_keys']
      user_account user['id'] do
        ssh_keys config['ssh_keys']
        action :manage
      end
    end
  end

  def create_app_vhost(app, user)
    template_cookbook, template_source = app['vhost_template'].split('::')

    template "#{node['nginx']['dir']}/sites-available/#{app['name']}.conf" do
      cookbook    template_cookbook
      source      template_source
      owner       "root"
      mode        "0644"
      variables({
        app:              app,
        deploy_to_path:   "#{node['overseer']['root_path']}/#{app['name']}",
        log_path:         node['nginx']['log_dir'],
        ssl_certs_path:   node['overseer']['http']['ssl_certs_path'],
        ssl_private_path: node['overseer']['http']['ssl_private_path']
      })

      not_if      { template_cookbook == "none" }
      notifies    :reload, "service[nginx]"
    end

    nginx_site "#{app['name']}.conf"
  end
end
