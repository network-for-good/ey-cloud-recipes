#
# Cookbook Name:: cron
# Recipe:: default
#

# Find all cron jobs specified in attributes/cron.rb where current node name matches instance_name
#crons = node[:custom_crons].find_all {|c| c[:instance_name] == "#{node[:name]}" }
crons = {}

crons.each do |cron|
  cron cron[:name] do
    user     node['owner_name']
    action   :create
    minute   cron[:time].split[0]
    hour     cron[:time].split[1]
    day      cron[:time].split[2]
    month    cron[:time].split[3]
    weekday  cron[:time].split[4]
    command  cron[:command]
  end
end

case node[:instance_role]
when 'util', 'solo'
  node[:applications].keys.each do |app_name|
    template '/etc/cron.daily/clean_rails_cache_dir.sh' do
      source 'clean_rails_cache_dir.sh.erb'
      variables({
        app_dir: "/data/#{app_name}/shared/tmp/cache"
      })
      mode '0755'
    end
  end
end
