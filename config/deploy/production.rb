# IMPORTANT: You should change this to *your* server settings
# This is the configuration for the Smidig 2008 conference

set :environment, "production"
set :mongrel_port_start, 5200
set :mongrel_server_count, 4
set :domain, "smidig2008.no"

set :deploy_to, "/u/apps/#{application}"
set :database, "#{application}"