#
# Cookbook Name:: le
# Recipe:: configure
#
#
env = node[:environment][:framework_env]

execute "le register --account-key" do
  command "le register --account-key #{node[:rails_config]['api_key']} --hostname #{node[:hostname]} --name #{node[:applications].keys.first}"
  action :run
  not_if { File.exists?('/etc/le/config') }
end

follow_paths = [
  "/var/log/syslog",
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
    command "le follow #{path}; true"
    ignore_failure true
    action :run
  end
end
