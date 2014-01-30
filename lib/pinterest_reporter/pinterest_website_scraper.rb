class PinterestWebsiteScraper < PinterestInteractionsBase
  #podaje body dostaje hasha z wszystkimi boardami i ich statystykami dla danego boarda
  
  def get_pinterest_boards(html)
    page       = Nokogiri::HTML(html)
    #parse initial page
    board_data = Hash.new
    content = page.content
    #get scrubbedUser JSON and parse it with boards data
    #
     scrubbed_user = JSON.parse(content.match(/\{"scrubbedUser":.*\}/).to_s)
    # #scrubbed_user['tree']['children'][3]['children'][3]['children'][3]['children'][3].to_s
     json_boards = scrubbed_user['tree']['children'][3]['children'][2]['children'][0]['children'][0]['children'][0]['children']

    # #puts "json boards: #{scrubbed_user['tree']['children'][3]['children'][2]['children'][0]['children'][0]['children'][0]['children'][0].to_s.gsub("=>",":")}"

    json_boards.each do |board|
      board_id = board['resource']['options']['board_id']
      board_url =  board['children'][0]['options']['url']
      board_name = board['children'][0]['options']['title_text'].strip
      board_data[board_name] = {"id" => board_id, "url" => board_url}
    end
    # puts "#{board_data.to_s}"
    @conn = Faraday.new(url: WEB_FETCH_BOARDS_URL) do |faraday|
      faraday.request  :url_encoded
      faraday.use FaradayMiddleware::FollowRedirects
      faraday.adapter  Faraday.default_adapter
    end

  begin
    options = JSON.parse(content.match(/\{"field_set_key": "grid_item", "username":.*?\]{1}?\}{1}/).to_s)
    app_version = content.match(/"app_version": ".*?"/).to_s.split(":")[1].strip.match(/[^"]+/)
    #puts "Options: #{options['username'].to_s}"
    #puts "App version: #{app_version}"
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

    resp = @conn.get do |req|    
      req.params['source_url'] = "/#{options['username'].to_s}/"
      req.params['data'] = JSON.generate(data)
      req.params['-'] = 139094526248
      req.headers['X-Requested-With'] = 'XMLHttpRequest'
    end 
    content = resp.body 
    #puts "#{content}"
    #puts "data: #{JSON.generate(data).to_s}"
    scrubbed_user = JSON.parse("{#{resp.body.match(/"tree".*}},/).to_s.chop}")
    #scrubbed_user['tree']['children'][3]['children'][3]['children'][3]['children'][3].to_s
    json_boards = scrubbed_user['tree']['children']
    #puts "#{scrubbed_user.to_s}"
    #puts "json boards: #{scrubbed_user['tree']['children'].to_s}"
    
    json_boards.each do |board|
      board_id = board['resource']['options']['board_id']
      board_url =  board['children'][0]['options']['url']
      board_name = board['children'][0]['options']['title_text'].strip
      board_data[board_name] = {"id" => board_id, "url" => board_url}
    end


    #puts "#{board_data.to_s}"
    #boards   = resp.body.scan(/"title_text": "[^"]*{1}"/)
    #boards.each  do |b| 
    #  returnee << b.split(":")[1].strip.match(/[^"]+/).to_s.strip
    #end

  #puts "#{options['bookmarks'][0].to_s}"
  end while options['bookmarks'][0].to_s!="-end-"
   # puts "#{content}"
   # puts "#{board_data.to_s}"
   # puts "#{board_data.size}"
  return board_data
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

  def scrape_board_for_media_files(html)

  end

end