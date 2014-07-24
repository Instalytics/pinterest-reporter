class PinterestWebsiteScraper < PinterestInteractionsBase

  def get_followers(html, threshold, followers_to_process)
    processed_followers = 0
    page       = Nokogiri::HTML(html)
    followers_list = []
    content = page.content
    options = JSON.parse(content.match(/{"username": "\w+?", "bookmarks":[^-]*?\]}/).to_s)
    app_version = content.match(/"app_version": ".*?"/).to_s.split(":")[1].strip.match(/[^"]+/)
    followers = page.css("a[class=userWrapper]")
    followers.each do |follower|
      follower_name      = follower.text.tr("\n", "").strip.match(/\S.+?  /).to_s.strip
      follower_url       = follower.attribute('href').value
      follower_pins      = follower.text.tr("\n", "").strip.match(/\d*[,]?\d+ Pin/).to_s.strip.split[0].tr(",","")
      follower_followers = follower.text.tr("\n", "").strip.match(/\d*[,]?\d+ Follower/).to_s.strip.split[0].tr(",","")
      followers_list << {
        "profile_name" => follower_name,
        "url" => follower_url,
        "pins" => follower_pins,
        "followers" => follower_followers
      } if follower_followers.to_i >= threshold.to_i
      processed_followers = processed_followers + 1
      return followers_list if processed_followers >= followers_to_process
    end
    @conn = Faraday.new(url: WEB_FETCH_FOLLOWERS_URL) do |faraday|
      faraday.request  :url_encoded
      faraday.use FaradayMiddleware::FollowRedirects
      faraday.adapter  Faraday.default_adapter
    end
    begin
      context = {"app_version" => app_version, "https_exp" => false}
      mod = {"name" => "GridItems", "options" => {"scrollable" => true,
                                                  "show_grid_footer"=>false,"centered"=>true,"reflow_all"=>true,
                                                  "virtualize"=>true,"layout" => "fixed_height"}}
      data = {"options" => options,
              "context" => context,
              "module" => mod,
              "append"  => true,
              "error_strategy" => 1}
      resp = @conn.get do |req|
        req.params['source_url'] = "/#{options['username'].to_s}/followers/"
        req.params['data'] = JSON.generate(data)
        req.params['-'] = 139094526248
        req.headers['X-Requested-With'] = 'XMLHttpRequest'
      end
      body_json = JSON.parse(resp.body)
      page = Nokogiri::HTML(body_json['module']['html'])
      content = page.content
      followers = page.css("a[class=userWrapper]")

      followers.each do |follower|
        follower_name      = follower.text.tr("\n", "").strip.match(/\S.+?  /).to_s.strip
        follower_url       = follower.attribute('href').value
        follower_pins      = follower.text.tr("\n", "").strip.match(/\d*[,]?\d+ Pin/).to_s.strip.split[0].tr(",","")
        follower_followers = follower.text.tr("\n", "").strip.match(/\d*[,]?\d+ Follower/).to_s.strip.split[0].tr(",","")
        followers_list << {
          "profile_name" => follower_name,
          "url" => follower_url,
          "pins" => follower_pins,
          "followers" => follower_followers
        } if follower_followers.to_i >= threshold.to_i
        processed_followers = processed_followers + 1
        return followers_list if processed_followers >= followers_to_process
      end
      options = body_json['module']['tree']['resource']['options']
      app_version = body_json['client_context']['app_version']
    end while options['bookmarks'][0].to_s!="-end-"
    return followers_list
  end

  def get_pinterest_boards(html)
    page       = Nokogiri::HTML(html)
    return nil if !page.css("div[class~=errorMessage]").empty?
    board_data = Hash.new
    content = page.content
    scrubbed_user = JSON.parse(content.match(/\{"gaAccountNumbers":.*\}/).to_s)
    json_boards = scrubbed_user['tree']['children'][3]['children'][2]['children'][0]['children'][0]['children'][0]['children']
    json_boards.each do |board|
      partial_board_data = board['children'][0]['options']
      if board['children'][0]['options']['title_text'].nil?
        partial_board_data = board['children'][1]['options']
      end
      board_id = board['resource']['options']['board_id']
      board_url =  partial_board_data['url']
      board_name = partial_board_data['title_text'].strip
      board_data[board_name] = {"id" => board_id, "url" => board_url}
    end
    @conn = Faraday.new(url: WEB_FETCH_BOARDS_URL) do |faraday|
      faraday.request  :url_encoded
      faraday.use FaradayMiddleware::FollowRedirects
      faraday.adapter  Faraday.default_adapter
    end
    begin
      options = JSON.parse(content.match(/\{"field_set_key": "grid_item", "username":.*?\]{1}?\}{1}/).to_s)
      app_version = content.match(/"app_version": ".*?"/).to_s.split(":")[1].strip.match(/[^"]+/)
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
      scrubbed_user = JSON.parse("{#{resp.body.match(/"tree".*}},/).to_s.chop}")
      json_boards = scrubbed_user['tree']['children']
      json_boards.each do |board|
        partial_board_data = board['children'][0]['options']
        if board['children'][0]['options']['title_text'].nil?
          partial_board_data = board['children'][1]['options']
        end
        board_id = board['resource']['options']['board_id']
        board_url =  partial_board_data['url']
        board_name = partial_board_data['title_text'].strip
        board_data[board_name] = {"id" => board_id, "url" => board_url}
      end
    end while options['bookmarks'][0].to_s!="-end-"
    return board_data
  end

  def get_board_information(html)
    board_page      = Nokogiri::HTML(html)

    return nil if !board_page.content.match(/Follow Board/)
    board_name      = board_page.css("h1[class~=boardName]").text.strip
    full_name       = board_page.css("h4[class~=fullname]").text.strip
    description     = board_page.xpath("/html/body/div[1]/div[2]/div[1]/div[2]/div[1]/p/text()").to_s.strip
    followers_count = board_page.content.match(/"followers": "\d+"/).to_s.split(':')[1].strip.tr("\"","")
    pins_count      = board_page.content.match(/"pinterestapp:pins": "\d+"/).to_s.split(':')[2].strip.tr("\"","")
    return {"owner_name" => full_name, "board_name" => board_name, "description" => description, "pins_count" => pins_count, "followers_count" => followers_count}
  end

  def get_latest_pictures_from_board(html)
    board_page      = Nokogiri::HTML(html)
    #matcher = board_page.content.match(/"children": \[{"resource": {"name": "PinResource".*"uid": "Pin-\d*"}\]/)
    matcher = board_page.content.match(/{"resource": {"name": "PinResource".*"uid": "Pin-\d*"}/)
    media_files_json = JSON.parse("{\"children\" : [#{matcher}]}")
    media_table = media_files_json['children']
    if media_table == nil
      result = {
        result: 'error',
        message: "could not fetch media data from #{board_page}"
      }
    else
      result = parse_media_table(media_table)
    end
    result
  end

  def parse_media_table(media_table)
    result = []
    media_table.each do |entry|
      result.push(parse_single_entry(entry))
    end
    {
      result: 'ok',
      data: result
    }
  end

  def parse_single_entry(entry)
    {
      media_file_id: entry['resource']['options']['id'],
      images: entry['data']['images'],
      likes_count: entry['data']['like_count'],
      description: entry['data']['description'],
      comments: entry['data']['comment_count'],
      repin_count: entry['data']['repin_count'],
      created_at: entry['data']['created_at'],
      link_to_pin_page: "pin/#{entry['resource']['options']['id']}",
      is_video: entry['data']['is_video'],
      #board followers at time of posting
    }
  end

  def scrape_data_for_profile_page(html)
    page  =  Nokogiri::HTML(html)
    return nil if !page.css("div[class~=errorMessage]").empty?
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

  # def scrape_pin_data(html,media_file_id)
  #   # <a class="socialItem likes" href="/pin/2814818491206901/likes/">
  #   #         <em class="likeIconSmall"></em>
  #   #         <em class="socialMetaCount likeCountSmall">
  #   #             155
  #   #         </em>
  #   #     </a>
  #   board_page     = Nokogiri::HTML(html)
  #   likes          = page.css("a[href=\"/pin/#{media_file_id}/likes/\"]").text
  #   puts "likes: #{likes}"
  # end

  #def get_followers(html, followers_threshold)
  #scrape followers page
  #get followers
  #those with followers_number for their profile >= followers_threshold - add to result list
  #
  #repeat
  # => send request for another portion of followers
  # => scrape request response
  # => get followers data from response
  # => those with followers_number for their profile >= followers_threshold - add to result list
  # => prepare headers for new request
  #until no more followers left
  #

  #end

end
