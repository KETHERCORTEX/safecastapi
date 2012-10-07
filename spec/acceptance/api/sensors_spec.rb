require 'spec_helper'

feature "/api/sensors API endpoint" do
  before do
    @user = Fabricate(:user, :email => 'paul@rslw.com', :name => 'Paul Campbell')
  end
  let(:user) { @user.reload }

  let(:sensor) { Fabricate(:sensor) }

  scenario "create a radiation sensor" do

    post('/api/sensors',
      {
        :api_key        => user.authentication_token,
        :sensor => {
          :manufacturer         => "LND",
          :model                => "7317",
          :measurement_category => "radiation",
          :measurement_type     => "gamma",
        }
      },
      {
        'HTTP_ACCEPT' => 'application/json'
      }
    )
    result = ActiveSupport::JSON.decode(response.body)
    result['manufacturer'].should == 'LND'
    result['model'].should == '7317'
    result['measurement_category'].should == 'radiation'
    result['measurement_type'].should == 'gamma'
    
    idCreated = result.include?('id')
    idCreated.should == true
  end

  scenario "create an air sensor" do
    post('/api/sensors',
      {
        :api_key        => user.authentication_token,
        :sensor => {
          :manufacturer         => "Some Company",
          :model                => "M1234",
          :measurement_category => "air",
          :measurement_type     => "methane",
        }
      },
      {
        'HTTP_ACCEPT' => 'application/json'
      }
    )
    result = ActiveSupport::JSON.decode(response.body)
    result['manufacturer'].should == 'Some Company'
    result['model'].should == 'M1234'
    result['measurement_category'].should == 'air'
    result['measurement_type'].should == 'methane'
    
    idCreated = result.include?('id')
    idCreated.should == true

  end

  scenario 'get a list of sensors' do
    sensor.reload
    result = api_get('/api/sensors.json')

    result.length.should == 1
    result.first['manufacturer'].should == sensor.manufacturer
    result.first['model'].should == sensor.model
    result.first['measurement_category'].should == sensor.measurement_category
    result.first['measurement_type'].should == sensor.measurement_type
  end

end
