require 'sinatra'
require 'sinatra/mongo'
require 'rest-client'
require 'json'
require 'ostruct'
require_relative 'partials'

helpers Sinatra::Partials

HOST = "http://battlelog.battlefield.com/"
URL_SERVICE = "#{HOST}bf3/user/overviewBoxStats/<USER_ID>/"
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
  danilo_moret: "2832659982774753240",
  mjrocha_67: "2832660143837888346",
  juzepeleteiro: "2832658994934400286"
}

configure :development do
  set :mongo, 'mongodb://localhost:27017/bf3dashboard'
end

configure :production do
  set :mongo, ENV["MONGOLAB_URI"]
end

get '/' do
  @teams = mongo["teams"].find
  erb :index
end

get '/team/:name' do |name|
  @team = mongo["teams"].find_one(name: name)
  profile_ids = @team["soldiers"].collect {|hash| hash["profile_id"]}
  @soldiers = get_soldiers(profile_ids)
  
  @top_score = @soldiers.sort_by {|obj| obj.score}
  @top_score.reverse!

  @top_kills = @soldiers.sort_by {|obj| obj.kills }
  @top_kills.reverse!

  @highest_playtime = @soldiers.sort_by {|obj| obj.time_played }
  @highest_playtime.reverse!

  @score_minute = @soldiers.sort_by {|obj| obj.score.to_f / obj.time_played.to_f }
  @score_minute.reverse!

  erb :team
end

helpers do
  def get_soldiers profile_ids
    profile_ids.collect do |user_id|
      json_data = RestClient.get(URL_SERVICE.gsub("<USER_ID>", user_id))
      hash = JSON(json_data)["data"]["soldiersBox"].first
      new_soldier(hash)
    end
  end
  
  def new_soldier hash
    persona = hash["persona"]
    persona_id = persona["personaId"]
    picture = persona["picture"] ? "#{CDN_URL}#{PICTURE_PATH}#{persona["picture"]}.png" : "#{CDN_URL}#{PICTURE_PATH}bf3-us-assault.png"
    dogtag = hash["dogtagsForPersona"][persona_id]
    basic_dogtag = dogtag ? "#{CDN_URL}#{DOGTAG_PATH}la/t/#{dogtag["basicDogTag"]["image"]}.png" : "#{CDN_URL}#{DOGTAG_PATH}lb/t/defaulttag_right.png"
    advanced_dogtag = dogtag ? "#{CDN_URL}#{DOGTAG_PATH}lb/t/#{dogtag["advancedDogTag"]["image"]}.png" : "#{CDN_URL}#{DOGTAG_PATH}la/t/defaulttag_right.png"
    score = hash["score"].to_i
    time_played = hash["timePlayed"]
    rank_picture = "#{CDN_URL}/public/profile/bf3/stats/ranks/small/r#{hash["rank"]}.png"

    OpenStruct.new({
      id: persona_id,
      persona: persona,
      name: persona["personaName"],
      namespace: persona["namespace"],
      time_played: time_played,
      picture: picture,
      basic_dogtag: basic_dogtag,
      advanced_dogtag: advanced_dogtag,
      rank: hash["rank"],
      rank_picture: rank_picture,
      win_rate: "%.2f" % (hash["numWins"].to_f / hash["numLosses"].to_f),
      score: score,
      kills: hash["kills"],
      score_minute: ((score.to_f / time_played.to_f) * 60).round
    })
  end

  def number_format number, delimiter = ','
    parts = number.to_s.to_str.split('.')
    parts[0].gsub!(/(\d)(?=(\d\d\d)+(?!\d))/, "\\1#{delimiter}")
    parts.join
  end

  def host
    HOST
  end
end

module Sinatra
  module MongoHelper
    def mongo
      settings.mongo
    end
  end
end