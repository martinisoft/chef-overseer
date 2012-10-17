#
# Cookbook Name:: overseer
# Attributes:: default
#
# Author:: Aaron Kalin (<akalin@martinisoftware.com>)
#
# Copyright:: 2012, Aaron Kalin
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

default['overseer']['data_bag_name'] = "overseer_apps"
default['overseer']['root_path'] = "/srv"
default['overseer']['first_http_port'] = 8000
default['overseer']['http']['ssl_certs_path']    = "/etc/ssl/certs"
default['overseer']['http']['ssl_private_path']  = "/etc/ssl/private"
