require 'spec_helper'

feature "/air_imports API endpoint" do

  before(:each) do
    User.destroy_all
    @user ||= Fabricate(:user)
    @result ||= api_post('/air_imports',{
                                               :api_key        => @user.authentication_token,
                                               :air_import => {
                                                   :source => fixture_file_upload('/air0simple.log')
                                               }
                                           }, {'HTTP_ACCEPT' => 'application/json'})
  end

  context "just an upload" do
    scenario "response should be unprocessed" do
      @result['id'].should_not be_blank
      @result['status'].should == 'unprocessed'
      @result['md5sum'].should == '5333fa1135f8e95502f8dd0d8cd84898'
    end
  end

  context "after processing" do

    before(:each) { Delayed::Worker.new.work_off; AirImport.find_each(&:finalize!) }
    let!(:updated_result) do
      api_get(
          "/air_imports/#{@result['id']}",
          {},
          {'HTTP_ACCEPT' => 'application/json'}
      )
    end

    subject { updated_result }

    scenario "response should be processed" do
      updated_result['status'].should == 'done'
    end

    scenario "it should have imported a measurements for each value" do
      updated_result['measurements_count'].should == 4
    end
  end
end