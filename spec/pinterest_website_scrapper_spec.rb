require 'spec_helper'

describe PinterestWebsiteScraper do

  let(:ryansammy_web_profile) do
    VCR.use_cassette('get_profile_page') do
      PinterestWebsiteCaller.new.get_profile_page('ryansammy')
    end
  end
  let(:ryansammy_bmw_board) do
    VCR.use_cassette('get_board_page') do
      PinterestWebsiteCaller.new.get_board_page('ryansammy','bmw')
    end
  end

  let(:expected_result_from_profile_page_scraping) do
    {
      "profile_name"        => "Ryan Sammy",
      "followers_count"     => "868",
      "profile_description" => "Food Lover, BMW Fanatic, and Craft Beer Connoisseur",
      "boards_count"        => "81",
      "pins_count"          => "1793",
      "likes_count"         => "279",
      "followed"            => "524"
    }
  end

  let(:expected_results_from_bmw_board_scraping) do
    {
      "board_name"      => "BMW",
      "description"     => "The cars I dream about.",
      "pins_count"      => "241",
      "followers_count" => "492"
    }
  end

  describe '#scrape_data_for_profile_page' do
    it 'gets the data from page' do
      VCR.use_cassette('scrape_data_for_profile_page') do
        expect(subject.scrape_data_for_profile_page(ryansammy_web_profile)).
          to eq(expected_result_from_profile_page_scraping)
      end
    end
    
    it 'returns list of all boards for profile page' do
      VCR.use_cassette('get_pinterest_boards') do
        expect(subject.get_pinterest_boards(ryansammy_web_profile).size).
        to eq(81)
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
