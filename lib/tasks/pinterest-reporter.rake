namespace "pinterest-reporter" do

  #desc 'get popular pintrest users'
  # task :get_popular_pinterest_users => :environment do
  #   #begin
  #     require 'popular_pinterest_users'
  #     InstagramerGetter::Main.new
  #   #rescue Exception => e
  #     #ExceptionNotifier.notify_exception(e)
  #   #end
  # end

  # desc 'get data on the pinterest user'
  # task :get_pinterest_user, [:profile] => [:environment] do |t, args| do
  #   begin

  #   end
  # end

  #desc 'observe hashtag'
  #task :observe_hashtag, [:hashtag] => :environment do |t, args|
    #begin
      #require 'instagram_hashtag_observer'
      #InstagramHashtagObserver.new.get_hashtag_info(args[:hashtag])
    #rescue Exception => e
      #ExceptionNotifier.notify_exception(e)
    #end
  #end

  #desc 'update comments and likes counts on InstagramMediaFiles' 
  #task 'update_comments_and_likes_counts_on_imf' => :environment do
    #begin
      #require 'instagram_hashtag_observer'
      #InstagramMediaFilesObserver.new.get_all_comments_and_likes
    #rescue Exception => e
      #ExceptionNotifier.notify_exception(e)
    #end
  #end

end

