require 'sinatra'
require 'rest-client'

get '/' do
  url_service = "http://battlelog.battlefield.com/bf3/user/overviewBoxStats/<USER_ID>/"
  # profile-identifer
  users = {
    tuliornelas: "2832658994908040861",
    danielfmartins: "2832660143811904223",
    brunofmsouza: "2832660143832117465",
    leosipe: "2832658801630550806"
  }

  data = users.values.collect do |user_id|
    RestClient.get(url_service.gsub("<USER_ID>", user_id))
  end

  puts data

  erb :index
end