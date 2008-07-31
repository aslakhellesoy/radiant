# IMPORTANT: You should change this to *your* server settings
# This is the configuration for the Smidig 2008 conference

# Setup before running deploy
#  Add personal public key to authorized keys for deploy
#  Create production database (remote rake db:create RAILS_ENV=production? after setup?)

# After cap deploy you must ALWAYS update extension assets:
#  cap invoke COMMAND="cd /u/apps/staging/smidig2008/current && rake db:migrate:extensions radiant:extensions:update_all RAILS_ENV=staging"

set :application, "smidig2008"
set :use_sudo, false

set :domain, "smidig2008.no"

# gem install capistrano-ext
set :stages, %w(production staging)
set :default_stage, "staging"
require 'capistrano/ext/multistage'

# If you aren't deploying to /u/apps/#{application} on the target
# servers (which is the default), you can specify the actual location
# via the :deploy_to variable:

# If you aren't using Subversion to manage your source code, specify
# your SCM below:
# http://github.com/guides/deploying-with-capistrano
default_run_options[:pty] = true

set :scm, "git"
set :branch, "master"
set :scm_user, 'aslakhellesoy'
set :repository,  "git://github.com/#{scm_user}/radiant.git"
set :deploy_via, :remote_cache
set :git_enable_submodules, 1
set :remote, scm_user

set :user, 'deploy'
set :runner, "deploy"

ssh_options[:paranoid] = false

role :app, domain
role :web, domain
role :db,  domain, :primary => true

# http://jointheconversation.org/railsgit
# Copy  server config after updating code
task :update_config, :roles => [:app] do
  run "cp -Rf #{shared_path}/config/* #{release_path}/config"
end

after "deploy:update_code", :update_config

# http://www.shanesbrain.net/2007/5/30/managing-database-yml-with-capistrano-2-0
namespace :db do
  desc "Create database yaml in shared path" 
  task :default do
    puts "Please enter the database password:"
    db_config =  <<-EOF
#{environment}:
  adapter: mysql
  database: #{database}
  username: smidig_no
  password: #{password}
  host: localhost
  encoding: utf8
EOF
    run "mkdir -p #{shared_path}/config" 
    put db_config, "#{shared_path}/config/database.yml" 
  end
  
  
  task :create, :roles => :db, :only => { :primary => true } do
    rake = fetch(:rake, "rake")
    rails_env = fetch(:rails_env, environment)
    migrate_env = fetch(:migrate_env, "")
    migrate_target = fetch(:migrate_target, :latest)
 
    run "cd #{current_path}; #{rake} RAILS_ENV=#{rails_env} #{migrate_env} db:create"
    run "cd #{current_path}; #{rake} RAILS_ENV=#{rails_env} #{migrate_env} db:migrate:extensions"
    run "cd #{current_path}; #{rake} RAILS_ENV=#{rails_env} #{migrate_env} radiant:extensions:update_all"
  end
end
after "deploy:setup", "db:default"

before "deploy:migrate", "db:create"

