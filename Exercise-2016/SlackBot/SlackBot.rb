# coding: utf-8
require 'json'
require 'uri'
require 'yaml'
require 'net/https'

class SlackBot
  def initialize(settings_file_path = "settings.yml")
    config = YAML.load_file(settings_file_path) if File.exist?(settings_file_path)
    # This code assumes to set incoming webhook url as evironment variable in Heroku
    # SlackBot uses settings.yml as config when it serves on local
    @incoming_webhook = ENV['INCOMING_WEBHOOK_URL'] || config["incoming_webhook_url"]
    @suntory_bar = ENV['BAR_API_KEY'] || config["bar_api_key"]
  end

  def post_message(string, options = {})
    p @incoming_webhook
    payload = options.merge({text: string})
    uri = URI.parse(@incoming_webhook)
    res = nil
    json = payload.to_json
    request = "payload=" + json

    Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      res = http.post(uri.request_uri, request)
    end

    return res
  end

  def naive_respond(params, options = {})
    
    res = {text: "#{params[:name]} #{params[:msg]}"}.merge(options).to_json
    p res
    return res
  end
  
end
