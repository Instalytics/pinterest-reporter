class PinterestMediaFile
  include Mongoid::Document
  include Mongoid::Timestamps

  validates :pinterest_media_id, uniqueness: true

  field :pinterest_username,   type: String
  field :pinterest_board_name, type: String
  field :pinterest_media_id,   type: String
  field :pinterest_link,       type: String
  field :for_observed_ig_tag,  type: String
  field :pinterest_created_at, type: DateTime

  has_many   :instagram_media_file_probes
  belongs_to :pinterest_board
end
