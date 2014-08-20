require 'spec_helper'

describe PinterestWebsiteCaller do

  describe '#initialize' do

    it 'has proper Faraday connection object' do
      expect(subject.website_connection.class).to be(Faraday::Connection)
    end
  end

  describe '#get_profile_page' do
    it 'returns website' do
      #VCR.use_cassette('get_profile_page') do
        #puts "#{subject.get_profile_page('ryansammy')}"
        expect(subject.get_profile_page('ryansammy')).not_to be(nil)
      #end
    end

    it 'returns pinterest board page' do
      #VCR.use_cassette('get_board_page') do
        expect(subject.get_board_page('ryansammy','cars')).not_to be(nil)
      #end
    end
  end
end