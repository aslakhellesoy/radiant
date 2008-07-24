# IMPORTANT: You should change this to *your* server settings
# This is the configuration for the Smidig 2008 conference

set :environment, "staging"
set :mongrel_port_start, 5250
set :mongrel_server_count, 2
set :domain, "staging.smidig2008.no"

set :deploy_to, "/u/apps/staging/#{application}"
set :database, "staging_#{application}"
set :rails_env, "staging"