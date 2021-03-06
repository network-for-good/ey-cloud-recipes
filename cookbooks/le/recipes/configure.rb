#
# Cookbook Name:: le
# Recipe:: configure
#
#
env = node[:environment][:framework_env]
rails_config = node[:config_hash]['defaults'].deep_merge(node[:config_hash][env])

execute "create /etc/le" do
  command "mkdir /etc/le"
  not_if { Dir.exists?("/etc/le") }
end

template '/etc/le/config' do
	source 'config.erb'
	variables({
		user_key: rails_config['logentries']['api_key'],
		agent_key: rails_config['logentries']['agent_key'],
    role: node[:instance_role]
	})
	mode '0644'
end

execute "le register --account-key" do
  command "le register --account-key #{rails_config['logentries']['api_key']} --hostname #{node[:hostname]} --name #{node[:applications].keys.first}"
  action :run
  not_if { File.exists?('/etc/le/config') }
end

follow_paths = [
  "/var/log/syslog",
  "/var/log/engineyard/apps/#{node[:applications].keys.first}/#{env}_activejob.log"
]

case node[:instance_role]
when 'app', 'app_master', 'solo'
  ["/var/log/nginx/passenger.log"].each { |file| follow_paths << file }

  (node[:applications] || []).each do |app_name, app_info|
    follow_paths << "/var/log/nginx/#{app_name}.error.log"
    follow_paths << "/var/log/engineyard/apps/#{app_name}/#{env}.log"
  end
when 'util'
  (node[:applications] || []).each do |app_name, app_info|
    follow_paths << "/var/log/engineyard/apps/#{app_name}/#{env}.log"
  end
when 'db_master', 'db_slave'
end

follow_paths.each do |path|
  execute "le follow #{path}" do
    command "le follow #{path}"
    ignore_failure false
    action :run
  end
end
