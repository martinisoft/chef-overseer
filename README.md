Description
===========

Overseer is an opinionated web application setup cookbook that configures
running applications in their own user directory. This is a fork of
the [FanFare](https://github.com/fnichol/chef-fanfare) cookbook by
[fnichol](https://github.com/fnichol) but does not enforce database
setup and uses rvm in place of rbenv.

Requirements
============

Chef 10.12.0+

Assumptions
-----------

* You are deploying a rails application
* You have setup a database server
* You don't mind using RVM to manage your ruby environments
* You use runit to keep your application up and running
* You use nginx to serve your apps
* You use [foreman](https://github.com/ddollar/foreman) to define which applications are run

Platform
--------

* Ubuntu

Tested on:

* Ubuntu 12.04

Cookbooks
---------

This cookbook depends on the following external cookbooks:

* [user](http://community.opscode.com/cookbooks/user) (by [fnichol](https://github.com/fnichol))
* [nginx](http://community.opscode.com/cookbooks/nginx) (by Opscode)
* [rvm](https://github.com/fnichol/chef-rvm) (by [fnichol](https://github.com/fnichol))
* [runit](http://community.opscode.com/cookbooks/runit) (by Opscode)

Attributes
==========

### root_path

Defaults to "/srv" because its a logical place to put web applications
according to the [Filesystem Hierarchy Standard](http://en.wikipedia.org/wiki/Filesystem_Hierarchy_Standard).

Usage
=====

* Add the recipe[overseer] to your run_list on all nodes you wish to run your application
* Create a data bag item under "overseer_apps" for your application name
* Tag each node with {appname}\_node so overseer can employ those apps on those
  particular servers

License and Author
==================

- Author:: [Fletcher Nichol](https://github.com/fnichol) (<[fnichol@nichol.ca](mailto:fnichol@nichol.ca)>)
- Author:: Aaron Kalin (<akalin@martinisoftware.com>)

Copyright:: 2012 Aaron Kalin, Fletcher Nichol

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
