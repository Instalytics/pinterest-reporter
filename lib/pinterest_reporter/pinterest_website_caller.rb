# encoding: UTF-8

class PinterestWebsiteCaller < PinterestInteractionsBase
  attr_accessor :website_connection

  def initialize
    @website_connection = Faraday.new(url: WEB_BASE_URL) do |faraday|
      faraday.request  :url_encoded
      faraday.use FaradayMiddleware::FollowRedirects
      faraday.adapter  Faraday.default_adapter
    end
  end

  def get_profile_page(account_name)
    @website_connection.get("/#{account_name}").body
  end

  def get_board_page(account_name, board_name)
    begin
      @website_connection.get("/#{account_name}/#{board_name.strip.downcase.tr(" ", "-")}").body
    rescue Exception => ex
      raise "Could not fetch board #{board_name} for #{account_name} pinterest profile. Obtained exception: #{ex.message}"
    end
  end

  def get_followers_page(account_name)
    @website_connection.get("/#{account_name}/followers").body
  end
end