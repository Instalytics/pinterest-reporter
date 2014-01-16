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

class InstagramMediaFilesObserver < InstagramInteractionsBase
  RETRIES = 5

  def initialize
    puts "Starting InstagramHashtagObserver!"
    @mongoid_config = Rails.root.join("config", "mongoid.yml").to_s

    @faraday_api_connection = Faraday.new(url: API_BASE_URL) do |f|
      f.request  :url_encoded
      f.adapter  Faraday.default_adapter
    end

    @faraday_direct_connection = Faraday.new(url: WEB_BASE_URL) do |f|
      f.request  :url_encoded
      f.adapter  Faraday.default_adapter
    end
  end

  def get_all_comments_and_likes
    InstagramMediaFile.all.each do |imf|
      count_likes_and_comments_for_media(imf)
    end
  end

  def count_likes_and_comments_for_media(imf_obj)
    imf_obj.instagram_media_file_probes.create({
      likes:    get_likes_for_media(imf_obj._id),
      comments: count_comments_for_media(imf_obj.instagram_media_id),
      instagram_media_file_id: imf_obj.id
    })
  end

  private
    def get_likes_for_media(media_id)
      returnee = nil
      url_for_pic = InstagramMediaFile.find(media_id).
        instagram_link.gsub!("http://instagram.com", "")

      response = @faraday_direct_connection.get("#{url_for_pic}")
      doc      = Nokogiri::HTML(response.body)

      doc.css('script').each do |k|
        begin
          JSON.parse(k.content.match(/\[{"componentName".*}\]/).to_s).each do |el|
            returnee = el['props']['media']['likes']['count']
          end
        rescue
        end
      end
      returnee
    end

    def count_comments_for_media(media_id)
      response_body = call_api_for_media(media_id, 'comments')
      JSON.parse(response_body)['data'].size
    end

    def call_api_for_media(media_id, action='comments', retries=0)
      if retries > 0
        puts "#call_api_for_media retrying media:#{media_id} for the #{retries}" 
      end
      response = @faraday_api_connection.get do |req|
        req.url "/v1/media/#{media_id}/#{action}?client_id=#{TOKENS.shuffle.first}"
        req.options = { timeout: 15, open_timeout: 15}
      end

      if response.status == 200
        return response.body
      else
        return { data: {error: "ERR400" }}.to_json if retries == RETRIES
        return call_api_for_media(media_id, action, retries=retries+1)
      end
    end
end