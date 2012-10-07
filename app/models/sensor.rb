class Sensor < ActiveRecord::Base
  has_and_belongs_to_many :devices
  has_many :measurements

  validates :manufacturer,  :presence => true
  validates :model,         :presence => true

  #we validate type so that no generic sensors are allowed.
  validates :measurement_type,          :presence => true
  validates :measurement_category,      :presence => true

  def serializable_hash(options)
    options ||= {}
    super(options.merge(:only => [
      :id, :manufacturer, :model, :measurement_type, :measurement_category
    ]))
  end

  def name
    "#{self.manufacturer} - #{self.model}"
  end

  def self.generic_radiation
    generic_params = {
      :manufacturer => 'Generic',
      :model        => 'Radiation Sensor',
      :measurement_category => 'radiation',
      :measurement_type => 'generic'
    }
    s = self.where(generic_params)
    if s.empty?
      sensor = self.create(generic_params)
    else
      sensor = s.first
    end
    sensor
  end

  def self.search_by_params(params)
    search_params = {}
    
    [:manufacturer, :model, :serial_number, :category].each do |field|
      if params[field].present?
        search_params[field] = params[field]
      end
    end

    if search_params.empty?
      Sensor.page(params[:page] || 1)
    elsif search_params.include? :serial_number
      Sensor.where(search_params).first
    else
      Sensor.where(search_params)
    end
  end
end
