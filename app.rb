require 'sinatra'
require 'rest-client'
require 'json'
require 'ostruct'

get '/' do
  url_service = "http://battlelog.battlefield.com/bf3/user/overviewBoxStats/<USER_ID>/"
  # profile-identifer
  users = {
    tuliornelas: "2832658994908040861",
    danielfmartins: "2832660143811904223",
    brunofmsouza: "2832660143832117465",
    leosipe: "2832658801630550806"
  }

  @data = users.values.collect do |user_id|
    json_data = RestClient.get(url_service.gsub("<USER_ID>", user_id))
    JSON(json_data)["data"]["soldiersBox"].first
  end
  
  @data.sort_by! {|hash| hash["score"].to_i}
  @data.reverse!

  erb :index
end