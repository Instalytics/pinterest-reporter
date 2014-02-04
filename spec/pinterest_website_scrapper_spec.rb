require 'spec_helper'

describe PinterestWebsiteScraper do

  let(:ryansammy_web_profile) do
    VCR.use_cassette('get_profile_page') do
      PinterestWebsiteCaller.new.get_profile_page('ryansammy')
    end
  end

  let(:non_existent_web_profile) do
    VCR.use_cassette('get_non_existent_profile_page') do
      PinterestWebsiteCaller.new.get_profile_page('xz')
    end
  end
  
  let(:ryansammy_bmw_board) do
    VCR.use_cassette('get_board_page') do
      PinterestWebsiteCaller.new.get_board_page('ryansammy','bmw')
    end
  end

  let(:maryannrizzo_web_profile) do
    VCR.use_cassette('get_profile_page') do
      PinterestWebsiteCaller.new.get_profile_page('maryannrizzo')
    end
  end

  let(:maryannrizzo_everything_board) do
    VCR.use_cassette('get_board_page_everything') do
      PinterestWebsiteCaller.new.get_board_page('maryannrizzo','everything')
    end
  end

  let(:expected_result_from_profile_page_scraping) do
    {
      "profile_name"        => "Ryan Sammy",
      "followers_count"     => "868",
      "profile_description" => "Food Lover, BMW Fanatic, and Craft Beer Connoisseur",
      "boards_count"        => "82",
      "pins_count"          => "1794",
      "likes_count"         => "279",
      "followed"            => "525"
    }
  end

  let(:expected_results_from_bmw_board_scraping) do
    {
      "owner_name"      =>"Ryan Sammy",
      "board_name"      => "BMW",
      "description"     => "The cars I dream about.",
      "pins_count"      => "241",
      "followers_count" => "491"
    }
  end

  describe '#scrape_data_for_profile_page' do
    it 'gets the data from page' do
      VCR.use_cassette('scrape_data_for_profile_page') do
        expect(subject.scrape_data_for_profile_page(ryansammy_web_profile)).
          to eq(expected_result_from_profile_page_scraping)
      end
    end
    
    it 'returns nil when trying to get non existent profile_page' do
      VCR.use_cassette('scrape_data_for_profile_page') do
        expect(subject.scrape_data_for_profile_page(non_existent_web_profile)).to be(nil)
      end    
    end
    
    it 'returns list of all boards for profile page' do
      VCR.use_cassette('get_pinterest_boards') do
        expect(subject.get_pinterest_boards(maryannrizzo_web_profile).size).
        to eq(231)
      end
    end

  end

  describe "#get boards data" do
    it "gets data for given pinterest board" do
      VCR.use_cassette('get_board_information') do
        expect(subject.get_board_information(ryansammy_bmw_board)).
        to eq(expected_results_from_bmw_board_scraping)
      end
    end
  end
end
