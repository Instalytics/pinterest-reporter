# This is the 'Probe' meaning we create these in
# certain intervals to keep track of changes of number comments and likes
#
class PinterestMediaFileProbe
  include Mongoid::Document
  include Mongoid::Timestamps

  #TODO: What data file probe should store for pinterest media files?
  
  #field :likes,    type: Integer
  #field :comments, type: Integer

  belongs_to :pinterest_media_file
end
