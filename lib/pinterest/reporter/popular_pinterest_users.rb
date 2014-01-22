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

    def get_pinterest_boards(pinterest_user)
      conn = Faraday.new(:url => "http://www.pinterest.com" ) do |faraday|
        faraday.use FaradayMiddleware::FollowRedirects
        faraday.adapter :net_http
      end
      response = conn.get "/#{pinterest_user.profile_name}"
      page     = Nokogiri::HTML(response.body)
      titles   = page.css("div[class~=title]")
      
      titles.each do title
        response = conn.get "/#{pinterest_user.profile_name}/#{title.text.strip.downcase.tr(" ", "-")}"
        board_page     = Nokogiri::HTML(response.body)
        b = PinterestBoard.create({
          board_name:       title.text.strip.downcase.tr(" ", "-"), 
          description:      board_page.xpath("/html/body/div[1]/div[2]/div[1]/div[2]/div[1]/p/text()").strip
          followers_count:  board_page.xpath("/html/body/div[1]/div[2]/div[1]/div[2]/div[1]/div/ul/li[2]/a/text()").to_s.split[0], 
          pins_count:       board_page.xpath("/html/body/div[1]/div[2]/div[1]/div[2]/div[1]/div/ul/li[1]/a/div/text()").to_s.split[0]
        })
        pinterest_user << b
      end
    end

    def get_pinterest_user_data(profile_name)
      #dostaje profile name
      #tworze usera
      #wyciagam jego boardy
      #tworze pinterest boardy dla danego usera

      response = Faraday.get("http://www.pinterest.com/#{profile_name}")
      page     = Nokogiri::HTML(response.body) 
      
      i = PinterestUser.create({ 
        username:          profile_name,
        email:             '',
        followers:         page.xpath("/html/body/div[1]/div[2]/div[1]/div[2]/div[2]/ul[2]/li[1]/a/span/text()").to_s.split[0].to_i / 1000,
        bio:               page.css("div[class~=userProfileHeaderBio]").text,
        created_at:        DateTime.now,
        updated_at:        DateTime.now,
        already_presented: false
      })
      if i.valid? get_pinterest_boards(i)

      puts "#{i.inspect}"  
      # doc = Nokogiri::HTML(response.body)
      # doc.css('script').each do |k|
      #   begin
      #     JSON.parse(k.content.match(/\[{"componentName".*}\]/).to_s).each do |el|
      #       returnee = el['props']['user']
      #     end
      #   rescue
      #   end
      # end    
    end
  end
end

module PintresterGetter
  class Main < PinterestInteractionsBase

    #get pinterest users - how to get most popular ones? 
    FOLLOWERS_LIMIT = 10

    def initialize
      puts "Starting PinterestGetter!"
      @mongoid_config = Rails.root.join("config", "mongoid.yml").to_s

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
