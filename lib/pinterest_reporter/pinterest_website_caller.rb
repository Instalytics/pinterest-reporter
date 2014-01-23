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
    @website_connection.get("/#{account_name}/#{board_name.strip.downcase.tr(" ", "-")}").body
  end
end