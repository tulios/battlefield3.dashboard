require 'sinatra'
require 'sinatra/mongo'
require 'rest-client'
require 'json'
require 'ostruct'

require_relative 'partials'
require_relative 'json_response'

helpers Sinatra::Partials

HOST = "http://battlelog.battlefield.com/"
URL_SERVICE = "#{HOST}bf3/user/overviewBoxStats/<USER_ID>/"
# profile-identifer

CDN_URL = "http://battlelog-cdn.battlefield.com"
PICTURE_PATH = "/public/profile/kits/s/"
DOGTAG_PATH = "/public/profile/bf3/stats/dogtags/"

configure :development do
  set :mongo, 'mongodb://localhost:27017/bf3dashboard'
end

configure :production do
  set :mongo, ENV["MONGOLAB_URI"]
end

get '/' do
  @teams = mongo["teams"].find
  
  if params[:format] and params[:format] == "json"
    json @teams.map {|team| team.delete("key") ; team}
  else
    erb :index
  end
end

get '/team/:name' do |name|
  @team = mongo["teams"].find_one(name: name)
  profile_ids = @team["soldiers"].collect {|hash| hash["profile_id"]}
  @soldiers = get_soldiers(profile_ids)

  @top_score = @soldiers.sort_by {|obj| obj.score}
  @top_score.reverse!

  @top_kills = @soldiers.sort_by {|obj| obj.kills}
  @top_kills.reverse!

  @highest_playtime = @soldiers.sort_by {|obj| obj.time_played}
  @highest_playtime.reverse!

  @score_minute = @soldiers.sort_by {|obj| obj.score_minute}
  @score_minute.reverse!

  @kill_death_ratio = @soldiers.sort_by {|obj| obj.kill_death_ratio}
  @kill_death_ratio.reverse!

  if params[:format] and params[:format] == "json"
    @team.delete("key")
    json({
      team: @team,
      leaderboard: {
        top_score: @top_score.map {|o| o.instance_variable_get("@table")},
        top_kills: @top_kills.map {|o| o.instance_variable_get("@table")},
        highest_playtime: @highest_playtime.map {|o| o.instance_variable_get("@table")},
        score_minute: @score_minute.map {|o| o.instance_variable_get("@table")},
        kill_death_ratio: @kill_death_ratio.map {|o| o.instance_variable_get("@table")}
      }
    })
    
  else
    erb :team
  end
end

post '/team/:name/new_soldier' do |name|
  @team = mongo["teams"].find_one(name: name)
  if params["team_key"] == @team["key"]
    soldier = get_soldiers([params["profile_id"]]).first
    if soldier
      mongo["teams"].update(
        {"_id" => @team["_id"]},
        {
          "$push" => {
            "soldiers" => {
              "name" => soldier.name.downcase,
              "profile_id" => soldier.profile_id.to_s
            }
          }
        })
    end
  end

  redirect "/team/#{name}"
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
    num_wins = hash["numWins"].to_f
    num_losses = hash["numLosses"].to_f
    kills = hash["kills"].to_i
    deaths = hash["deaths"].to_i
    kill_death_ratio = (kills.to_f / deaths.to_f)
    
    win_rate = 0
    if  num_wins > 0 and num_losses > 0
     win_rate = (num_wins / num_losses)
   end

    score_minute = 0
    if score.to_f > 0 and time_played.to_f > 0
      score_minute = ((score.to_f / time_played.to_f) * 60).floor
    end

    OpenStruct.new({
      id: persona_id,
      url: "#{host}bf3/soldier/#{persona["personaName"]}/stats/#{persona_id}/#{persona["namespace"]}/",
      profile_id: persona["userId"],
      persona: persona,
      name: persona["personaName"],
      namespace: persona["namespace"],
      time_played: time_played,
      time_played_formatted: duration_format(time_played),
      picture: picture,
      basic_dogtag: basic_dogtag,
      advanced_dogtag: advanced_dogtag,
      rank: hash["rank"],
      rank_picture: rank_picture,
      win_rate: "%.2f" % win_rate,
      score: score,
      score_formatted: number_format(score),
      score_minute: score_minute,
      kills: kills,
      deaths: deaths,
      kill_death_ratio: kill_death_ratio,
      kill_death_ratio_formatted: "%.2f" % kill_death_ratio
    })
  end

  def number_format number, delimiter = ','
    parts = number.to_s.to_str.split('.')
    parts[0].gsub!(/(\d)(?=(\d\d\d)+(?!\d))/, "\\1#{delimiter}")
    parts.join
  end
  
  def duration_format seconds
		seconds = seconds.to_i
		mins  = (seconds / 60) % 60
		hours = seconds / (60 * 60)
					
		"#{hours}h #{mins}m"
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