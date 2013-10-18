name             "overseer"
maintainer       "Aaron Kalin"
maintainer_email "akalin@martinisoftware.com"
license          "Apache 2.0"
description      "Opinionated web application deployment."
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "0.6.11"

supports "ubuntu"

recommends "nginx"
depends "user"
depends "runit"
depends "rvm"
