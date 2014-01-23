class PinterestWebsiteScraper 
  #podaje body dostaje hasha z wszystkimi boardami i ich statystykami dla danego boarda
  
  def get_pinterest_boards(html)
    page       = Nokogiri::HTML(html)
    returnee   = page.css("div[class~=title]")    
    return returnee
  end

  def get_board_information(html)
    board_page      = Nokogiri::HTML(html)
    board_name      = board_page.css("h1[class~=boardName]").text
    description     = board_page.xpath("/html/body/div[1]/div[2]/div[1]/div[2]/div[1]/p/text()").strip
    followers_count = board_page.xpath("/html/body/div[1]/div[2]/div[1]/div[2]/div[1]/div/ul/li[2]/a/text()").to_s.split[0], 
    pins_count      = board_page.xpath("/html/body/div[1]/div[2]/div[1]/div[2]/div[1]/div/ul/li[1]/a/div/text()").to_s.split[0]
    
    return {board_name => {"description" => description, "pins_count" => pins_count, "followers_count" => followers_count}} 
  end

  def get_profile_information(html)
    page  =  Nokogiri::HTML(html)
    profile_name    = page.css("h1[class~=userProfileHeaderName]").text
    followers_count = page.xpath("/html/body/div[1]/div[2]/div[1]/div[2]/div[2]/ul[2]/li[1]/a/span/text()").to_s.strip.split[0]
    bio             = page.css("div[class~=userProfileHeaderBio]").text
    boards          = page.xpath("/html/body/div[1]/div[2]/div[1]/div[2]/div[2]/ul[1]/li[1]/a/span/text()").to_s.strip.split[0]
    pins            = page.css("div[class~=PinCount]").text.to_s.split[0]
    likes           = page.xpath("/html/body/div[1]/div[2]/div[1]/div[2]/div[2]/ul[1]/li[3]/a/text()").to_s.strip.split[0]
    followed        = page.xpath("/html/body/div[1]/div[2]/div[1]/div[2]/div[2]/ul[2]/li[2]/a/text()").to_s.strip.split[0] 
    
    return {"profile_name" => profile_name, "followers_count" => followers_count, "profile_description" => bio,
      "boards_count" => boards, "pins_count" => pins, "likes_count" => likes, "followed" => followed}
  end

end