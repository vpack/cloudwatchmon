#
# Cookbook Name::       cloudwatch_monitoring
# Description::         Base configuration for cloudwatch_monitoring
# Recipe::              default
# Author::              Alexis Midon
#
# See https://github.com/alexism/cloudwatch_monitoring
#
# Copyright 2013, Alexis Midon
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

include_recipe 'cron'

group node[:cw_mon][:group] do
  action :create
end

user node[:cw_mon][:user] do
  home node[:cw_mon][:home_dir]
  group node[:cw_mon][:group]
  action :create
end

directory node[:cw_mon][:home_dir] do
  group node[:cw_mon][:group]
  owner node[:cw_mon][:user]
end

bash 'Installing cloudwatchmon.' do
  code <<-EOH
    easy_install pip
    pip install boto
    pip install cloudwatchmon
  EOH
end

options = ['--from-cron'] + node[:cw_mon][:options]

if iam_role = IAM::role
  log "IAM role available: #{iam_role}"
else
  log "no IAM role available. CloudWatch Monitoring scripts will use IAM user #{node[:cw_mon][:user]}" do
    level :warn
  end
  vars = {}
  begin
    user_creds = Chef::EncryptedDataBagItem.load(node[:cw_mon][:aws_users_databag], node[:cw_mon][:user])
    vars[:access_key_id] = user_creds['access_key_id']
    vars[:secret_access_key] = user_creds['secret_access_key']
    log "AWS key for user #{ node[:cw_mon][:user]} found in databag #{node[:cw_mon][:aws_users_databag]}"
  rescue
    vars =node[:cw_mon]
  end

  template "#{install_path}/awscreds.conf" do
    owner node[:cw_mon][:user]
    group node[:cw_mon][:group]
    mode 0644
    source 'awscreds.conf.erb'
    variables :cw_mon => vars
  end

  options << "--aws-credential-file #{install_path}/awscreds.conf"
end

cron_d 'cloudwatch_monitoring' do
  minute "*"
  user node[:cw_mon][:user]
  command %Q{/bin/mon-put-instance-stats.py #{(options).join(' ')} || logger -t cloudwatch-mon "status=failed exit_code=$?"}
end
