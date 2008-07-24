# mongrel-based overrides of the default tasks

namespace :deploy do
  namespace :mongrel do
    [ :stop, :start, :restart ].each do |t|
      desc "#{t.to_s.capitalize} the mongrel appserver"
      task t, :roles => :app do
        set :mongrel_conf, "#{current_path}/config/mongrel_cluster.yml"
        #invoke_command checks the use_sudo variable to determine how to run the mongrel_rails command
        invoke_command "mongrel_rails cluster::#{t.to_s} -C #{mongrel_conf}", :via => run_method
      end
    end
    
    task :config do
    	mongrel_config = <<-END
--- 
user: #{runner}
group: #{runner}
log_file: log/mongrel.log
cwd: #{current_path}
port: #{mongrel_port_start}
servers: #{mongrel_server_count}
environment: #{environment}
pid_file: tmp/pids/mongrel.pid
address: 127.0.0.1
	END
      run "mkdir -p #{shared_path}/config"
      put mongrel_config, "#{shared_path}/config/mongrel_cluster.yml"
      invoke_command "echo #{current_path}, #{shared_path}"
    end
  end
  
  namespace :nginx do
    task :config do
      require 'erb'
    	nginx_config_template_text = File.open(File.dirname(__FILE__) + "/nginx.conf.erb").read
      ngingx_config = ERB.new(nginx_config_template_text, nil, "<>").result(binding)
      run "mkdir -p #{shared_path}/config" 
      put ngingx_config, "#{shared_path}/config/#{environment}_#{application}.conf"
    end

    desc "Setup nginx configuration and restart nginx"
    task :restart do
      # In order for this to work, the "deploy" user needs to be able
      #  to do svcadm
      # set :nginx_config, "/opt/nginx/conf/sites/#{application}.conf"
      set :nginx_config, "#{shared_path}/config/#{environment}_#{application}.conf"
      set :nginx_config_target, "/opt/nginx/conf/sites/#{environment}_#{application}.conf"
      run "/usr/bin/test ! -f #{nginx_config_target} -o #{nginx_config} -nt #{nginx_config_target} " +
        " && cp #{nginx_config} #{nginx_config_target} && svcadm restart nginx"
    end
  end
# after "deploy", "deploy:nginx"

  desc "Custom restart task for mongrel cluster"
  task :restart, :roles => :app, :except => { :no_release => true } do
    deploy.mongrel.restart
  end

  desc "Custom start task for mongrel cluster"
  task :start, :roles => :app do
    deploy.mongrel.start
  end

  desc "Custom stop task for mongrel cluster"
  task :stop, :roles => :app do
    deploy.mongrel.stop
  end

end

after "deploy:setup", "deploy:mongrel:config"
after "deploy:setup", "deploy:nginx:config"

after "deploy:cold", "deploy:nginx:restart"