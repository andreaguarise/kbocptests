#!/bin/ruby

require "net/https"
require "uri"
require "json"
validUnitTypes=["ramGB","storageGB","VCPU","DRYRUN"]

pricePerDaysPerUnit={"ramGB" => 0.168, "storageGB" => 0.059, "VCPU" => 0.168}




input= ARGV[0]
metric = ARGV[1]
if not validUnitTypes.include?(metric)
puts "Valid unit types: #{validUnitTypes.to_s}"
exit
end

file = File.read(input)
parsed =JSON::parse(file)
parsed.each do |user|
  puts user["target"].to_s
  thisUser = user["target"].to_s
 
  puts "#{thisUser}"
  
    amount = 0.0
    user["datapoints"].each do |data,date|
      unitType = metric
      if unitType == "DRYRUN"
        next
      end
      if unitType == "ramGB"
        if data
          data = data/(1024*1024*1024)
        end
      end
      if unitType == "storageGB"
        if data
          data = data/(1024*1024*1024)
        end
      end
      partial = data*pricePerDaysPerUnit[unitType]
      amount = amount+partial
      puts "#{thisUser}: #{Time.at(date)} --> #{data} --> #{partial} --> #{amount}"
      
    end
end