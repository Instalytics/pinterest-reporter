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

module NokoParser
  class Main

    def contact_data_email(data)
      if data.match(/([^@\s*]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})/i) != nil ? true : false
        return data.match(/([^@\s*]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})/i).to_s
      end
    end

    def contact_data(data)
      # checking for email
      if data.match(/([^@\s*]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})/i) != nil ? true : false
        return data.gsub(',', '')
      end

      %w(contact business Business Facebook facebook fb email Twitter twitter Contact FB tumblr Blog blog mail http www).each do |ci|
        return data.gsub(',', '') if data.include?(ci)
      end
      return nil
    end

    def get_followers_number(follower_name)
      returnee = nil
      conn = Faraday.new(:url => "https://instagram.com" ) do |faraday|
        faraday.use FaradayMiddleware::FollowRedirects
        faraday.adapter :net_http
      end

      response = conn.get "/#{follower_name}"

      doc = Nokogiri::HTML(response.body)
      doc.css('script').each do |k|
        begin
          JSON.parse(k.content.match(/\[{"componentName".*}\]/).to_s).each do |el|
            returnee = el['props']['user']
          end
        rescue
        end
      end

      i = PinterestUser.create({ 
        username:          returnee['username'],
        email:             contact_data_email(returnee['bio']),
        followers:         returnee['counts']['followed_by'].to_i / 1000,
        bio:               contact_data(returnee['bio']),
        created_at:        DateTime.now,
        updated_at:        DateTime.now,
        already_presented: false
      })
      print "." if i.valid?
    end
  end
end

module PintresterGetter
  class Main < PinterestInteractionsBase

    #get pinterest user and 
    FOLLOWERS_LIMIT = 10

    def initialize
      puts "Starting PinterestGetter!"
      @mongoid_config = Rails.root.join("config", "mongoid.yml").to_s

      # board_resp = Faraday.get("http://www.pinterest.com/#{self.pinterest_profile_name}/#{self.pinterest_board_name}")
      # board_page = Nokogiri::HTML(board_resp.body) 
      # # puts "account name: #{board_page.css("h4[class~=fullname]").text} |"
      # # puts "profile_picture_url: #{board_page.xpath("/html/body/div[1]/div[2]/div[1]/div[2]/div[1]/div/div/div/a/div/img/@src")} |"
      # # puts "description: #{board_page.xpath("/html/body/div[1]/div[2]/div[1]/div[2]/div[1]/p/text()").strip} |"
      # # puts "image_count: #{board_page.xpath("/html/body/div[1]/div[2]/div[1]/div[2]/div[1]/div/ul/li[1]/a/div/text()").to_s.split[0]}.to_i} |"
      # # puts "follower_count: #{board_page.xpath("/html/body/div[1]/div[2]/div[1]/div[2]/div[1]/div/ul/li[2]/a/text()").to_s.split[0].to_i} |"
    
      # social_media_profile = SocialMediaProfile.new({
      #   social_network:         SocialNetwork.where(network_name:'Pinterest').first,
      #   profile_name:           self.pinterest_profile_name,
      #   account_name:           board_page.css("h4[class~=fullname]").text,
      #   pinterest_board_name:   self.pinterest_board_name, 
      #   profile_picture_url:    board_page.xpath("/html/body/div[1]/div[2]/div[1]/div[2]/div[1]/div/div/div/a/div/img/@src"),
      #   description:            board_page.xpath("/html/body/div[1]/div[2]/div[1]/div[2]/div[1]/p/text()").strip,
      #   image_count:            board_page.xpath("/html/body/div[1]/div[2]/div[1]/div[2]/div[1]/div/ul/li[1]/a/div/text()").to_s.split[0].to_i,
      #   follower_count:         board_page.xpath("/html/body/div[1]/div[2]/div[1]/div[2]/div[1]/div/ul/li[2]/a/text()").to_s.split[0].to_i,
      # })

      conn = Faraday.new(:url => API_BASE_URL ) do |faraday|
        faraday.request  :url_encoded
        faraday.adapter  Faraday.default_adapter
      end

      response = conn.get do |req|
        req.url "/v1/media/popular?client_id=#{TOKENS.shuffle.first}"
        req.options = { timeout: 15, open_timeout: 15}
      end

      data = JSON.parse(response.body)['data']

      puts
      puts 'getting new users from instagram'
      puts
      data.each do |u|
        usr_name = u['user']['username']
        NokoParser::Main.new.get_followers_number(usr_name)
      end
    end
  end
end
