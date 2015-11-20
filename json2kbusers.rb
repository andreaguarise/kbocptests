#!/bin/ruby

require "net/https"
require "uri"
require "json"

iaasUsers = ["user0","user1","user2","user3","user4","user5","user6","user7","user8","user9"]
paasUsers = ["user10","user11","user12","user13","user14","user15"]

file = File.read("/root/one-consumptiom_vm.json")

parsed =JSON::parse(file)
parsed.each do |user|
  puts user["target"].to_s
        thisUser = user["target"].to_s
        kburi = URI.parse("http://localhost:8080/1.0/kb/accounts?externalKey=#{thisUser}")
        kbhttp = Net::HTTP.new(kburi.host, kburi.port)
        kbhttp.use_ssl = false

        kbrequest = Net::HTTP::Get.new(kburi.request_uri)
        kbrequest.basic_auth("admin", "password")
        kbrequest['X-Killbill-ApiKey'] = "bob"
        kbrequest['X-Killbill-ApiSecret'] = "lazar"
        kbresponse = kbhttp.request(kbrequest)
        #puts kbresponse
        thisUserId =""
        thisUserBundle = ""
        thisUserSubscriptionId =""
        kbparsed =JSON::parse(kbresponse.body)
        if kbparsed["accountId"]; then
    puts "user: #{thisUser} exists with accountId; #{kbparsed["accountId"]}"
    puts "Set AUTO_INVOICING_OFF for user #{thisUser}"
    kburi = URI.parse("http://localhost:8080/1.0/kb/accounts/#{kbparsed["accountId"]}/tags?tagList=00000000-0000-0000-0000-000000000002")
                kbhttp = Net::HTTP.new(kburi.host, kburi.port)
                kbhttp.use_ssl = false
                kbrequest = Net::HTTP::Post.new(kburi.request_uri)
                kbrequest.basic_auth("admin", "password")
                kbrequest['X-Killbill-ApiKey'] = "bob"
                kbrequest['X-Killbill-ApiSecret'] = "lazar"
                kbrequest['X-Killbill-CreatedBy'] = "admin"
    kbresponse = kbhttp.request(kbrequest)
    type = case
    when iaasUsers.include?(thisUser)
      "IaaS"
    when paasUsers.include?(thisUser)
      "PaaS"
    else
      "noBundle"
    end
    puts "User: #{thisUser} will have a #{type} subscription."
  else
    puts "user: #{thisUser} do NOT exists. Creating It"
    kburi = URI.parse("http://localhost:8080/1.0/kb/accounts")
                        kbhttp = Net::HTTP.new(kburi.host, kburi.port)
                        kbhttp.use_ssl = false
                        kbrequest = Net::HTTP::Post.new(kburi.request_uri)
                        kbrequest.basic_auth("admin", "password")
                        kbrequest['X-Killbill-ApiKey'] = "bob"
                        kbrequest['X-Killbill-ApiSecret'] = "lazar"
                        kbrequest['X-Killbill-CreatedBy'] = "admin"
                        kbrequest['Content-Type'] = "application/json"
                        payload ={
                                "name" => "Mr. #{thisUser}",
        "externalKey" => thisUser,
        "currency" => "EUR",
        "email" => "#{thisUser}@changeme.email"
                                }.to_json
                        puts payload.to_s
                        kbrequest.body = payload
                        kbresponse = kbhttp.request(kbrequest)
      puts kbresponse
  end
end