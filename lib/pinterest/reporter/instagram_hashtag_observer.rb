require 'rubygems'

require 'faraday'
require 'faraday_middleware'
require 'json'
require 'capybara'
require 'capybara/dsl'
require 'csv'
require 'nokogiri'
require 'open-uri'
require 'mongoid'
require 'mongoid_to_csv'

class InstagramHashtagObserver < InstagramInteractionsBase

  def initialize
    puts "Starting InstagramHashtagObserver!"
    @mongoid_config = Rails.root.join("config", "mongoid.yml").to_s

    @faraday_connection = Faraday.new(url: API_BASE_URL) do |f|
      f.request  :url_encoded
      #f.response :logger
      f.adapter  Faraday.default_adapter
    end
  end

  def get_hashtag_info(tag)
    response = @faraday_connection.get do |req|
      req.url "/v1/tags/#{tag}/media/recent?client_id=#{TOKENS.shuffle.first}"
      req.options = { timeout: 15, open_timeout: 15}
    end

    instagram_media_files = []
    JSON.parse(response.body)['data'].each do |el|
      pub = SocialMediaProfile.where(profile_name: el['user']['username']).first
      iu  = InstagramUser.where(username: el['user']['username']).first
      next if iu.blank? && pub.blank? # we skip this loop iteration if there is no user for this media in our DB

      instagram_media_files << InstagramMediaFile.create({
        instagram_username:   el['user']['username'],
        instagram_media_id:   el['id'],
        instagram_type:       el['type'],
        #instagram_user:       iu,
        instagram_link:       el['link'],
        for_observed_ig_tag:  tag,
        instagram_created_at: Time.at(el['created_time'].to_i)
      })
    end
    puts "InstagramHashtagObserver#get_hashtag_info got #{instagram_media_files.size} new InstagramMediaFiles"

  end
end
