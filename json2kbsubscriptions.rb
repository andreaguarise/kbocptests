#!/bin/ruby

require "net/https"
require "uri"
require "json"

iaasUsers = ["user0","user1","user2","user3","user4","user5","user6","user7","user8","user9"]
paasUsers = ["user10","user11","user12","user13","user14","user15"]
subscriptionStart = "2014-01-01"

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
  puts kbresponse.body.to_s
  parsed = JSON::parse(kbresponse.body)
  paasBundle = {}
  if ( parsed["subscriptions"] )
    paasBundle = { "accountId" => parsed["subscriptions"].first["accountId"].to_s,
    "bundleId" => parsed["subscriptions"].first["bundleId"].to_s,
    "subscriptionId" => parsed["subscriptions"].first["subscriptionId"].to_s }
  end
  paasBundle
end

def subscribeIaaS (userName, kbUserId, subscriptionStart)
  requestBody = {
                                "accountId" => kbUserId,
        "externalKey" => "#{userName}-IaaS",
        "productName" => "IaaS",
        "productCategory" => "BASE",
        "billingPeriod" => "MONTHLY",
        "priceList" => "DEFAULT",
                                }
  kbresponse = RESTCall(
    "http://localhost:8080/1.0/kb/subscriptions?requestedDate=#{subscriptionStart}",
    "POST",
    requestBody
  )
  puts kbresponse.body.to_s
end

def subscribePaaS (userName, iaasBundle, subscriptionStart)
  requestBody = {
                                "accountId" => iaasBundle["accountId"],
                                "bundleId" => iaasBundle["bundleId"],
        "externalKey" => "#{userName}-PaaS",
        "productName" => "PaaS",
        "productCategory" => "ADD_ON",
        "billingPeriod" => "MONTHLY",
        "priceList" => "DEFAULT",
                                }
  kbresponse = RESTCall(
    "http://localhost:8080/1.0/kb/subscriptions/#{iaasBundle["subscriptionId"]}?requestedDate=#{subscriptionStart}",
    "PUT",
    requestBody
  )
  puts kbresponse.body.to_s
end

file = File.read("/root/one-consumptiom_vm.json")

parsed =JSON::parse(file)
parsed.each do |user|
  puts user["target"].to_s
        thisUser = user["target"].to_s
        thisUserId =""
        thisUserBundle = ""
        thisUserSubscriptionId =""
        kburi = URI.parse("http://localhost:8080/1.0/kb/accounts?externalKey=#{thisUser}")
        kbresponse = RESTCall("http://localhost:8080/1.0/kb/accounts?externalKey=#{thisUser}", "GET" , {})
        kbparsed =JSON::parse(kbresponse.body)
        if kbparsed["accountId"]; then
    puts "user: #{thisUser} exists with accountId; #{kbparsed["accountId"]}"
    type = case
    when iaasUsers.include?(thisUser)
      "IaaS"
    when paasUsers.include?(thisUser)
      "PaaS"
    else
      "noBundle"
    end
    iaasBundle = getIaaS(thisUser)
    puts "User: #{thisUser} will have a #{type} subscription."
    case 
    when type == "IaaS"
      if iaasBundle["bundleId"]
        puts "IaaS bundle already exists for this user"
        puts iaasBundle.to_s
      else
        puts "Creating IaaS bundle for user #{thisUser}"
        subscribeIaaS(thisUser, kbparsed["accountId"], subscriptionStart)
      end
    when type == "PaaS"
      if iaasBundle["bundleId"]
        puts "IaaS bundle (PaaS pre-requisite )already exists for this user"
        puts iaasBundle.to_s
      else
        puts "Creating IaaS bundle (Paas pre-requisite) for user #{thisUser}"
        subscribeIaaS(thisUser, kbparsed["accountId"], subscriptionStart)
      end
      paasBundle = getPaaS(thisUser)
      if paasBundle["bundleId"]
        puts "PaaS bundle addon already exists for this user"
        puts paasBundle.to_s
      else
        puts "Creating PaaS bundle addon for user #{thisUser}"
        subscribePaaS(thisUser, iaasBundle, subscriptionStart)
      end
    end
  else
    puts "user: #{thisUser} do NOT exists."
  end
end