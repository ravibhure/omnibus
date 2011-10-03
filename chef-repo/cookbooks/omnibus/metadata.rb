maintainer       "Opscode, Inc."
maintainer_email "cookbooks@opscode.com"
license          "Apache 2.0"
description      "Installs/Configures omnibus"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "1.0.0"

depends 'windows'
depends 'wix'
depends '7-zip'