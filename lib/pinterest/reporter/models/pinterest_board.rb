# THIS IS ONLY USED BY THE RAKE TASK FOR AUTOMATING 
# GATHERING OF POPULAR USERS
class PinterestBoard
  include Mongoid::Document

  validates :board_name, uniqueness: true

  field :board_name,        type: String
  field :description,       type: String
  field :followers_count,   type: String
  field :pins_count,        type: String

  has_many :pinterest_media_files
  
  def formated_created_at
    self.created_at.strftime('%d-%m-%Y (%H:%M)')
  end

  def self.to_csv(options = {})
    CSV.generate(options) do |csv|
      csv << %w(social_media_profile_name followers_count followers_count_short contact_details about_me created_at) 
      all.each do |pinterest_user|
        csv << [ pinterest_user.username,
                 pinterest_user.followers.to_i * 1000,
                 pinterest_user.followers,
                 pinterest_user.email,
                 pinterest_user.bio,
                 pinterest_user.created_at
               ]

      end
    end
  end

end