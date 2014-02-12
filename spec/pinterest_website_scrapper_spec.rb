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

  let(:cespins_mens_clothing_board) do
    VCR.use_cassette('get_board_page') do
      PinterestWebsiteCaller.new.get_board_page('CESPINS','men-clothing')
    end
  end


  let(:ryansammy_non_existent_board) do
    VCR.use_cassette('get_board_page') do
      PinterestWebsiteCaller.new.get_board_page('ryansammy','i_do_not_exist_board')
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

  let(:expected_results_from_cespins_mens_clothing_board_scraping) do
    {
      "owner_name"      => "",
      "board_name"      => "Men Clothing",
      "description"     => "Welcome to this board and many thanks for all your contributions. Men's clothing only. Constant repins will be deleted. Pins without source links will be deleted.    beautifulambience1@gmail.com",
      "pins_count"      => "43343",
      "followers_count" => "20967"
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
      VCR.use_cassette('get_pinterest_boards_list_all_boards') do
        expect(subject.get_pinterest_boards(maryannrizzo_web_profile).size).
        to eq(237)
      end
    end

    it 'returns nil if boards are being fetched for non existent profile page' do
      VCR.use_cassette('get_pinterest_boards_non_existent_profile_page') do
        expect(subject.get_pinterest_boards(non_existent_web_profile)).
        to be(nil)
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

    it "gets data for given pinterest board with large number of followers" do
      VCR.use_cassette('get_board_information') do
        expect(subject.get_board_information(cespins_mens_clothing_board)).
        to eq(expected_results_from_cespins_mens_clothing_board_scraping)
      end
    end

    it 'returns nil if non existing board name is used for fetching board information' do
      VCR.use_cassette('get_board_information_non_existend_board_name') do
        expect(subject.get_board_information(ryansammy_non_existent_board)).
        to be(nil)
      end
    end

  end
end
