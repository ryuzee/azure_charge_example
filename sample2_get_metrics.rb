require 'optparse'
require 'terminal-table'
require './lib/azassu'

option={}
OptionParser.new do |opt|
  opt.on('-a', '--application_id=VALUE')     {|v| option[:application_id] = v}
  opt.on('-c', '--client_secret=VALUE')      {|v| option[:client_secret] = v}
  opt.on('-f', '--filter=VALUE')             {|v| option[:filter] = v}
  opt.on("-m", "--resource_name=VALUE")      {|v| option[:resource_name] = v }
  opt.on("-n", "--resource_provider_ns=VALUE") {|v| option[:resource_provider_ns] = v }
  opt.on("-r", "--resource_group=VALUE")     {|v| option[:resource_group] = v }
  opt.on('-s', '--subscription_id=VALUE')    {|v| option[:subscription_id] = v}
  opt.on('-t', '--tenant_id=VALUE')          {|v| option[:tenant_id] = v}
  opt.on('-y', '--resource_type=VALUE')      {|v| option[:resource_type] = v}
  opt.on('-l', '--filter_type=VALUE')        {|v| option[:filter_type] = v}
  opt.on('-g', '--aggregation_type=VALUE')   {|v| option[:aggregation_type] = v}
  opt.parse!(ARGV)
end

[:application_id, :client_secret, :subscription_id, :resource_name].each do |k|
  if option[k].nil? or option[k].empty?
    puts "Option must be specified... Type ruby main.rb -h"
    exit
  end
end

# Get API Token
token = Azassu::Token.get(option[:application_id], option[:client_secret], option[:tenant_id])

unless option[:filter_type]
  option[:filter_type] = 'Percentage CPU'
end

unless option[:aggregation_type]
  option[:aggregation_type] = 'Average'
end

unless option[:filter]
  option[:filter] = Azassu::Metrics.generate_5mins_filter(option[:filter_type], option[:aggregation_type])
end

# Get Metrics (Easiest Way)
metrics = Azassu::Metrics.get_by_name(token, option[:subscription_id], option[:resource_name], option[:filter])
puts metrics

# Get Metrics
# metrics = Azassu::Metrics.get(token, option[:subscription_id], option[:resource_group], option[:resource_provider_ns], option[:resource_type], option[:resource_name], option[:filter])
# puts metrics
