
default[:cw_mon][:user]              = "cw_monitoring"
default[:cw_mon][:group]             = "cw_monitoring"
default[:cw_mon][:home_dir]          = "/home/#{node[:cw_mon][:user]}"

default[:cw_mon][:aws_users_databag] = "aws_users"
default[:cw_mon][:access_key_id]     = nil
default[:cw_mon][:secret_access_key] = nil

default[:cw_mon][:options] = %w{--disk-space-util  --disk-path=/ --disk-space-used
                                --disk-space-avail --swap-util --swap-used
                                --mem-util --mem-used --mem-avail}

