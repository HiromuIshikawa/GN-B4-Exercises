# coding: utf-8
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'json'
require 'uri'
require 'net/https'
require 'sinatra'
require 'SlackBot'



class MySlackBot < SlackBot
  @@table = {"北海道" => "01","青森県"=> "02","岩手県"=> "03","宮城県"=> "04","秋田県"=> "05","山形県"=> "06","福島県"=> "07","茨城県"=> "08","栃木県"=> "09","群馬県"=> "10","埼玉県"=> "11","千葉県"=> "12","東京都"=> "13","神奈川県"=> "14","新潟県"=> "15","富山県"=> "16","石川県"=> "17","福井県"=> "18","山梨県"=> "19","長野県"=> "20","岐阜県"=> "21","静岡県"=> "22","愛知県"=> "23","三重県"=> "24","滋賀県"=> "25","京都府"=> "26","大阪府"=> "27","兵庫県"=> "28","奈良県"=> "29","和歌山県"=> "30","鳥取県"=> "31","島根県"=> "32","岡山県"=> "33","広島県"=> "34","山口県"=> "35","徳島県"=> "36","香川県"=> "37","愛媛県"=> "38","高知県"=> "39","福岡県"=> "40","佐賀県"=> "41","長崎県"=> "42","熊本県"=> "43","大分県"=> "44","宮崎県"=> "45","鹿児島県"=> "46","沖縄県"=> "47"}

  def msg_perser(params)
    return nil if params[:user_name] == "slackbot" || params[:user_id] == "USLACKBOT"
    user_name = params[:user_name] ? "<@#{params[:user_id]}|#{params[:user_name]}>" : ""

    /@MoyaiBot\s(.*)/ =~ params[:text]
    msg = $1
    return {name: user_name, msg: msg}

  end
  
  def apipost(options = {})
    
    uri = URI.parse("http://webapi.suntory.co.jp/barnavi/v2/shops")
    
    http = Net::HTTP.new(uri.host, uri.port)
    res = nil
    req = Net::HTTP::Post.new(uri.path)
    params = {key: @suntory_bar, pattern: 0, format: "json", url: URL, count: 10}.merge(options)
    req.set_form_data(params)
    res = http.request(req)
    hash = JSON.parse(res.body)
    return hash
  end

  def make_responce(data, options)
    options = options.merge({attachments: [Hash.new,Hash.new,Hash.new,Hash.new,Hash.new,Hash.new,Hash.new,Hash.new,Hash.new,Hash.new]})
    hit_num = data["shops"]["results_returned"].to_i
    if hit_num == 0
      return nil
    else
      hit_num.times do |i|
        color_num = 0
        color_num = i%2 if i != 0
        color = ["#000000","#696969"]
        shop = data["shops"]["shop"][i]
        
        name = shop["name"]
        kana = shop["name_kana"]
        link = shop["url_pc"]
        thumb = shop["url_photo_l1"]
        address = shop["address"]
        open = shop["open"]

        resi = options[:attachments][i]
        resi[:color] = color[color_num]
        resi[:fallback] = name
        resi[:title] = name
        resi[:title_link] = link
        resi[:text] = kana
        resi[:thumb_url] = thumb
        resi[:fields] = [Hash.new,Hash.new]
        resi[:fields][0][:title] = ":round_pushpin:住所"
        resi[:fields][0][:value] = address
        resi[:fields][0][:short] = true
        resi[:fields][1][:title] = ":calendar:開店時間"
        resi[:fields][1][:value] = open
        resi[:fields][1][:short] = true
      end
      return options
    end
  end
  
  def exec_responds(params, options = {})
    if /「(.*)」と言って/ =~ params[:msg]
      params[:msg] = $1
      naive_respond(params, options)
    elsif /((.+)\s(.+))のbar/ =~ params[:msg]
      search = $1
      params[:msg] = "\n「#{search}」に一致するbarはありませんでした\n<http://bar-navi.suntory.co.jp/|詳しい検索はこちら(ページが変わります)>"
      keyword = Hash.new
      keyword[:pref] = @@table[$2]
      if keyword[:pref]    
        subkey = $3
        if /(.+駅)周辺/ =~ subkey
          keyword[:access] = $1
        else
          keyword[:address] = subkey
        end
        result = apipost(keyword)
        options = make_responce(result, options)
        if options
          hit = result["shops"]["results_returned"].to_i
          all = result["shops"]["results_available"].to_i
          params[:msg] = "\n「#{search}」のbar検索結果です(#{hit}/#{all}件表示)\n<http://bar-navi.suntory.co.jp/|詳しい検索はこちら(ページが変わります)>"
        end
      end
      naive_respond(params,options)
    else
      params[:msg] = "Hi!"
      naive_respond(params, options)
    end
  end
  
end

slackbot = MySlackBot.new

set :environment, :production

get '/' do
  'SlackBotServer<br>
  Powered by <a href="http://webapi.suntory.co.jp/barnavidocs/"><span style="color: #0000ff; text-decoration: underline">Bar-Navi Web API</span></a>'
end

slackbot.post_message("",{username: "MoyaiBot", icon_emoji: ":moyai:"})

post '/slack' do
  content_type :json
  p params
  res_info = slackbot.msg_perser(params)
  if res_info
    slackbot.exec_responds(res_info, username: "MoyaiBot")
  end
end

