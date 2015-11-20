#!/bin/ruby

require "net/https"
require "uri"
require "json"

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

file = File.read("/root/one-consumptiom_disk.json")
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
  iaasBundle ={}
  kbparsed =JSON::parse(kbresponse.body)
  if kbparsed["accountId"]; then
      thisUserId = kbparsed["accountId"]
      iaasBundle = getIaaS(thisUser)
  end
  
  if iaasBundle["subscriptionId"] != ""; then
    user["datapoints"].each do |data,date|
      unitType = "storageGB"
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
      puts "#{iaasBundle["accountId"]}, subscriptionId:#{iaasBundle["subscriptionId"]}: #{Time.at(date)} --> #{data}"
      kbresponse3 = RESTCall(
        "http://127.0.0.1:8080/1.0/kb/usages",
        "POST",
                    {
                                "subscriptionId" => iaasBundle["subscriptionId"],
                                "unitUsageRecords" => [{
                                        "unitType" => unitType,
                                        "usageRecords" => [{
                                                "recordDate" => (Time.at(date)+(0)).strftime("%Y-%m-%d"),
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