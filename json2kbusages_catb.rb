#!/bin/ruby

require "net/https"
require "uri"
require "json"
validUnitTypes=["ramGB","storageGB","VCPU","DRYRUN"]
offset = "0" 

def RESTCall (uri, method, body)
        kburi = URI.parse(uri)
        kbhttp = Net::HTTP.new(kburi.host, kburi.port)
        kbhttp.use_ssl = false
        kbrequest = case
        when method == "GET"
                Net::HTTP::Get.new(kburi.request_uri)
        when method == "POST"
                Net::HTTP::Post.new(kburi.request_uri)
        when method == "PUT"
                Net::HTTP::Put.new(kburi.request_uri)
        else
                exit -1
        end
        kbrequest.basic_auth("admin", "password")
        kbrequest['X-Killbill-ApiKey'] = "bob"
        kbrequest['X-Killbill-ApiSecret'] = "lazar"
        kbrequest['X-Killbill-CreatedBy'] = "admin"
        kbrequest['Content-Type'] = "application/json"
        kbrequest.body = body.to_json
        kbresponse = kbhttp.request(kbrequest)
end

def getIaaS(userName)
        kbresponse = RESTCall(
                "http://localhost:8080/1.0/kb/bundles?externalKey=#{userName}-IaaS",
                "GET",
                {}
        )
        parsed = JSON::parse(kbresponse.body)
        iaasBundle = {}
        if ( parsed["subscriptions"] )
                iaasBundle = { "accountId" => parsed["subscriptions"].first["accountId"].to_s,
                "bundleId" => parsed["subscriptions"].first["bundleId"].to_s,
                "subscriptionId" => parsed["subscriptions"].first["subscriptionId"].to_s }
        end
        iaasBundle
end

def getPaaS(userName)
        kbresponse = RESTCall(
                "http://localhost:8080/1.0/kb/bundles?externalKey=#{userName}-PaaS",
                "GET",
                {}
        )
        parsed = JSON::parse(kbresponse.body)
        paasBundle = {}
        if ( parsed["subscriptions"] )
                paasBundle = { "accountId" => parsed["subscriptions"].first["accountId"].to_s,
                "bundleId" => parsed["subscriptions"].first["bundleId"].to_s,
                "subscriptionId" => parsed["subscriptions"].first["subscriptionId"].to_s }
        end
        paasBundle
end

input= ARGV[0]
metric = ARGV[1]
if ARGV[2]
  offset = ARGV[2]
end
if not validUnitTypes.include?(metric)
puts "Valid unit types: #{validUnitTypes.to_s}"
exit
end

file = File.read(input)
parsed =JSON::parse(file)
parsed.each do |user|
  puts user["target"].to_s
  thisUser = user["target"].to_s
  kbresponse = RESTCall(
    "http://localhost:8080/1.0/kb/accounts?externalKey=#{thisUser}",
    "GET",
    {}
  )
  thisUserId =""
  thisUserBundle = ""
  thisUserSubscriptionId =""
  bundle ={}
  kbparsed =JSON::parse(kbresponse.body)
  if kbparsed["accountId"]; then
      thisUserId = kbparsed["accountId"]
      bundle = getIaaS(thisUser)
      if not bundle["subscriptionId"]
        puts "#{thisUser} no IaaS, trying PaaS"
        bundle = getPaaS(thisUser)
      end
  end
  puts "#{thisUser}, subscription:#{bundle["subscriptionId"]}"
  
  if bundle["subscriptionId"] != ""; then
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
      puts "#{bundle["accountId"]}, subscriptionId:#{bundle["subscriptionId"]}: #{(Time.at(date)+(offset.to_i)).strftime("%Y-%m-%d")} --> #{data}"
      kbresponse3 = RESTCall(
        "http://127.0.0.1:8080/1.0/kb/usages",
        "POST",
                    {
                                "subscriptionId" => bundle["subscriptionId"],
                                "unitUsageRecords" => [{
                                        "unitType" => unitType,
                                        "usageRecords" => [{
                                                "recordDate" => (Time.at(date)+(offset.to_i)).strftime("%Y-%m-%d"),
                                                "amount" => data
                                        }]
                                        }]
                                }
            )
    end
  else
    Puts "User Do not exists"
  end
end