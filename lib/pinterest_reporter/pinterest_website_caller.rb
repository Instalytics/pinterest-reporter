# encoding: UTF-8

class PinterestWebsiteCaller < PinterestInteractionsBase
  attr_accessor :website_connection

  def initialize
    @website_connection = Faraday.new(url: WEB_BASE_URL) do |faraday|
      faraday.request  :url_encoded
      faraday.headers['Connection'] = 'keep-alive'
      faraday.headers['User-Agent'] = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/34.0.1847.131 Safari/537.36'
      faraday.headers['Accept'] = 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8'
      faraday.headers['Accept-Language'] = 'en-US,en;q=0.8,pl;q=0.6'
      faraday.headers['Referer'] = 'https://www.google.pl/'
      faraday.headers['Dnt'] = '1'
      faraday.use FaradayMiddleware::FollowRedirects
      faraday.use FaradayMiddleware::FollowRedirects, limit: 5
      faraday.adapter  :excon
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

  def get_board_page_from_url(url)
    begin
      @website_connection.get(url).body
    rescue Exception => ex
      raise "Could not fetch board #{url}. Obtained exception: #{ex.message}"
    end
  end

  def get_followers_page(account_name)
    @website_connection.get("/#{account_name}/followers").body
  end
end