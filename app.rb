require 'sinatra'
require 'rest-client'
require 'json'
require 'ostruct'

URL_SERVICE = "http://battlelog.battlefield.com/bf3/user/overviewBoxStats/<USER_ID>/"
# profile-identifer

CDN_URL = "http://battlelog-cdn.battlefield.com"
PICTURE_PATH = "/public/profile/kits/s/"
DOGTAG_PATH = "/public/profile/bf3/stats/dogtags/"

USERS = {
  tuliornelas: "2832658994908040861",
  danielfmartins: "2832660143811904223",
  brunofmsouza: "2832660143832117465",
  leosipe: "2832658801630550806",
  el_mariel: "2832659598374270655",
  lurehendi: "2832660143835504606",
  danilo_moret: "2832659982774753240"
}

get '/' do  
  @soldiers = USERS.values.collect do |user_id|
    json_data = RestClient.get(URL_SERVICE.gsub("<USER_ID>", user_id))
    hash = JSON(json_data)["data"]["soldiersBox"].first
    new_soldier(hash)
  end

  @soldiers.sort_by! {|obj| obj.score}
  @soldiers.reverse!

  erb :index
end

helpers do
  def new_soldier hash
    persona = hash["persona"]
    persona_id = persona["personaId"]
    picture = persona["picture"] ? "#{CDN_URL}#{PICTURE_PATH}#{persona["picture"]}.png" : "#{CDN_URL}#{PICTURE_PATH}bf3-us-assault.png"
    dogtag = hash["dogtagsForPersona"][persona_id]
    basic_dogtag = dogtag ? "#{CDN_URL}#{DOGTAG_PATH}la/t/#{dogtag["basicDogTag"]["image"]}.png" : "#{CDN_URL}#{DOGTAG_PATH}lb/t/defaulttag_right.png"
    advanced_dogtag = dogtag ? "#{CDN_URL}#{DOGTAG_PATH}lb/t/#{dogtag["advancedDogTag"]["image"]}.png" : "#{CDN_URL}#{DOGTAG_PATH}la/t/defaulttag_right.png"

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
end
