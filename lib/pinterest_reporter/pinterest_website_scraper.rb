class PinterestWebsiteScraper < PinterestInteractionsBase
  #podaje body dostaje hasha z wszystkimi boardami i ich statystykami dla danego boarda
  
  def get_pinterest_boards(html)
    returnee = []
    page       = Nokogiri::HTML(html)
    #parse initial page
    boards   = page.css("div[class~=title]")
    boards.each  do |b| 
      returnee << b.text
    end
    content = page.content
    
    @conn = Faraday.new(url: WEB_FETCH_BOARDS_URL) do |faraday|
      faraday.request  :url_encoded
      faraday.use FaradayMiddleware::FollowRedirects
      faraday.adapter  Faraday.default_adapter
    end
  #  while content.match(/"bookmarks":.*end.{2}\]{1}}{1}/)==nil  do
  begin
    #do this while there is no  "bookmarks": ["-end-“] string in the response body
    options = JSON.parse(content.match(/\{"field_set_key": "grid_item", "username":.*?\]{1}?\}{1}/).to_s)
    app_version = content.match(/"app_version": ".*?"/).to_s.split(":")[1].strip.match(/[^"]+/)
    puts "Options: #{options['username'].to_s}"
    puts "App version: #{app_version}"



    #http://www.pinterest.com/resource/ProfileBoardsResource/get/
    context = {"app_version" => app_version, "https_exp" => false}
    mod = {"name" => "GridItems", "options" => {"scrollable" => true,
      "show_grid_footer"=>false,"centered"=>true,"reflow_all"=>true,
      "virtualize"=>true,"item_options"=>{"show_board_context"=>true,"show_user_icon"=>false},
      "layout" => "fixed_height"}}
    data = {"options" => options,
      "context" => context,
      "module" => mod,
      "append"  => true,
      "error_strategy" => 1}

    #{"options":{"field_set_key":"grid_item","username":"maryannrizzo",
    #"bookmarks":["LT4xNzc5NjI2OTE0NjQyNjY2OTk6MTQ4fDQxYmUyNzJiNmFkMjk5ZjhkMDBjZjkzMDFiMzA5ZThiMWVjY2VhYzYwZjY3OGVjNDJiYmJlM2MwMjQ3ZDkxMWQ="]},
    #"context":{"app_version":"","https_exp":false},"module":{"name":"GridItems",
    #"options":{"scrollable":true,"show_grid_footer":false,"centered":true,
    #"reflow_all":true,"virtualize":true,
    #"item_options":{"show_board_context":true,"show_user_icon":false},
    #"layout":"fixed_height"}},"append":true,"error_strategy":1}
    puts "data: #{JSON.generate(data).to_s}"


    resp = @conn.get do |req|    
      req.params['source_url'] = "/#{options['username'].to_s}/"                       # GET http://sushi.com/search?page=2&limit=100
      req.params['data'] = JSON.generate(data)
      req.params['-'] = 139094526248
      req.headers['X-Requested-With'] = 'XMLHttpRequest'
    end

    #<div class=\"title\">DIY Green Products</div>
    #puts "#{resp.body}"
    #page = resp.body.scan(/"title_text": "[^"]*{1}"/)
    boards   = resp.body.scan(/"title_text": "[^"]*{1}"/)
    boards.each  do |b| 
      returnee << b.split(":")[1].strip.match(/[^"]+/).to_s
    end
    content = resp.body 
  #  end
  puts "#{options['bookmarks'][0].to_s}"
  end while options['bookmarks'][0].to_s!="-end-"
    puts "#{returnee}"
    return returnee
  end

  def get_board_information(html)
    board_page      = Nokogiri::HTML(html)
    board_name      = board_page.css("h1[class~=boardName]").text
    description     = board_page.xpath("/html/body/div[1]/div[2]/div[1]/div[2]/div[1]/p/text()").to_s.strip
    followers_count = board_page.xpath("/html/body/div[1]/div[2]/div[1]/div[2]/div[1]/div/ul/li[2]/a/text()").to_s.strip.split[0]
    pins_count      = board_page.xpath("/html/body/div[1]/div[2]/div[1]/div[2]/div[1]/div/ul/li[1]/a/div/text()").to_s.strip.split[0]
    return {"board_name" => board_name, "description" => description, "pins_count" => pins_count, "followers_count" => followers_count}
  end

  def scrape_data_for_profile_page(html)
    page  =  Nokogiri::HTML(html)
    profile_name    = page.css("h1[class~=userProfileHeaderName]").text
    followers_count = page.xpath("/html/body/div[1]/div[2]/div[1]/div[2]/div[2]/ul[2]/li[1]/a/span/text()").to_s.strip.split[0].tr(",", "")
    bio             = page.css("p[class~=userProfileHeaderBio]").text
    boards          = page.xpath("/html/body/div[1]/div[2]/div[1]/div[2]/div[2]/ul[1]/li[1]/a/span/text()").to_s.strip.split[0].tr(",", "")
    pins            = page.css("div[class~=PinCount]").text.to_s.split[0].tr(",", "")
    likes           = page.xpath("/html/body/div[1]/div[2]/div[1]/div[2]/div[2]/ul[1]/li[3]/a/text()").to_s.strip.split[0].tr(",", "")
    followed        = page.xpath("/html/body/div[1]/div[2]/div[1]/div[2]/div[2]/ul[2]/li[2]/a/text()").to_s.strip.split[0].tr(",", "") 
    return {"profile_name" => profile_name, "followers_count" => followers_count, "profile_description" => bio,
      "boards_count" => boards, "pins_count" => pins, "likes_count" => likes, "followed" => followed}
  end

  def scrape_pin_data(html,media_file_id)
    # <a class="socialItem likes" href="/pin/2814818491206901/likes/">
    #         <em class="likeIconSmall"></em>
    #         <em class="socialMetaCount likeCountSmall">
    #             155
    #         </em>
    #     </a>
    board_page     = Nokogiri::HTML(html)
    likes          = page.css("a[href=\"/pin/#{media_file_id}/likes/\"]").text
    puts "likes: #{likes}"
  end

end