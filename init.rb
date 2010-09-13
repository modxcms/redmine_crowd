require 'redmine'
require 'crowd'

Redmine::Plugin.register :redmine_crowd_authenticator do
  name 'Redmine Crowd Authenticator plugin'
  author 'Kevin Marvin'
  description 'Allows authentication against Atlassian Crowd 1.6 (2.0 should be possible with a different crowd gem)'
  version '0.0.1'
  url 'http://assets.modx.com/redmine_crowd_authentication'
  author_url 'http://modxcms.com'
  
  menu :admin_menu, :crowd_authenticator, {:controller => "crowd_auth_sources", :action => "index"}, :caption => "CROWD Authentication"
end
