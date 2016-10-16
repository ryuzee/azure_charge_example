require 'optparse'
require 'terminal-table'
require './lib/azure_charge'

search_range = [:yesterday, :this_month, :last_month]
option={}
OptionParser.new do |opt|
  opt.on('-a', '--application_id=VALUE')     {|v| option[:application_id] = v}
  opt.on('-c', '--client_secret=VALUE')      {|v| option[:client_secret] = v}
  opt.on('-d', '--offer_durable_id=VALUE')   {|v| option[:offer_durable_id] = v}
  opt.on("-r", "--enum VALUE", search_range) {|v| option[:range] = v }
  opt.on('-s', '--subscription_id=VALUE')    {|v| option[:subscription_id] = v}
  opt.on('-t', '--tenant_id=VALUE')          {|v| option[:tenant_id] = v}
  opt.parse!(ARGV)
end

if option[:offer_durable_id].nil?
  option[:offer_durable_id] = 'MS-AZR-0003P'
end
if option[:range].nil?
  option[:range] = :this_month
end

[:application_id, :client_secret, :subscription_id, :tenant_id].each do |k|
  if option[k].nil? or option[k].empty?
    puts "Option must be specified... Type ruby main.rb -h"
    exit
  end
end

# Get API Token
token = AzureCharge.api_token(option[:application_id], option[:client_secret], option[:tenant_id])

# Get Usage
usages = AzureCharge.usages(token, option[:subscription_id], option[:range])

# Get RateCard
meters = AzureCharge.rate_meters(token, option[:subscription_id], option[:offer_durable_id])

# Combine Result
usages_with_rate = AzureCharge::usages_with_rate(usages, meters)

## Output result
total_cost = 0
rows = []
rows << AzureCharge::Usage.header_array
rows << :separator
usages_with_rate.each do |u|
  rows << u.data_array
  total_cost += u.cost
end

table = Terminal::Table.new :rows => rows
puts table
puts total_cost
