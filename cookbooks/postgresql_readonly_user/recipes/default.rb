#
# Cookbook Name:: postgresql_readonly_user
# Recipe:: default
#


reporting_user = 'reporting'
app = node['engineyard']['environment']['apps'].first
database_name = app['database_name']
database_username = 'postgres'
database_password = app['database_password']
sql = <<-EOL
CREATE ROLE #{reporting_user} LOGIN PASSWORD '!0QpalKsow92';
GRANT CONNECT ON DATABASE #{database_name} TO #{reporting_user};
GRANT USAGE ON SCHEMA public TO #{reporting_user};
GRANT SELECT ON ALL TABLES IN SCHEMA public TO #{reporting_user};
EOL

if node[:instance_role] == 'db_master'
  user_exists = `psql postgres -tAc "SELECT 1 FROM pg_roles WHERE rolname='#{reporting_user}'"`
  unless user_exists.strip == 1.to_s
    execute "psql" do
      command %Q{sudo -u #{database_username} /usr/bin/createuser -U #{database_username} -D -R -S #{reporting_user}}
      command %Q{sudo -u #{database_username} psql -U #{database_username} -d #{database_name} -c "#{sql}"}
    end
  end
end
