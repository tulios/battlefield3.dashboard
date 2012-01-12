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
    leosipe: "2832658801630550806",
    el_mariel: "2832659598374270655",
    lurehendi: "2832660143835504606"
  }

  cdn_url = "http://battlelog-cdn.battlefield.com"
  picture_path = "/public/profile/kits/s/"
  dogtag_path = "/public/profile/bf3/stats/dogtags/"

  @soldiers = users.values.collect do |user_id|
    json_data = RestClient.get(url_service.gsub("<USER_ID>", user_id))
    hash = JSON(json_data)["data"]["soldiersBox"].first

    persona = hash["persona"]
    persona_id = persona["personaId"]
    picture = persona["picture"] ? "#{cdn_url}#{picture_path}#{persona["picture"]}.png" : "#{cdn_url}#{picture_path}bf3-us-assault.png"
    dogtag = hash["dogtagsForPersona"][persona_id]
    basic_dogtag = dogtag ? "#{cdn_url}#{dogtag_path}la/t/#{dogtag["basicDogTag"]["image"]}.png" : "#{cdn_url}#{dogtag_path}lb/t/defaulttag_right.png"
    advanced_dogtag = dogtag ? "#{cdn_url}#{dogtag_path}lb/t/#{dogtag["advancedDogTag"]["image"]}.png" : "#{cdn_url}#{dogtag_path}la/t/defaulttag_right.png"

    OpenStruct.new({
      id: persona_id,
      persona: persona,
      name: persona["personaName"],
      namespace: persona["namespace"],

      picture: picture,
      basic_dogtag: basic_dogtag,
      advanced_dogtag: advanced_dogtag,
      rank: hash["rank"],
      win_rate: "%.2f" % (hash["numWins"].to_f / hash["numLosses"].to_f),
      score: hash["score"].to_i,
      kills: hash["kills"]
    })
  end

  @soldiers.sort_by! {|obj| obj.score}
  @soldiers.reverse!

  erb :index
end
