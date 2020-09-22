require "csv"

# TODO: Move this out of models
# Encapsulates CSV Export logic into a single class. `SUPPORTED_TYPES` lists
# the classes for which this can work.
class DataExport
  SUPPORTED_TYPES = %w(
    Adjustment
    BarcodeItem
    DiaperDriveParticipant
    Distribution
    Donation
    DonationSite
    Item
    Partner
    Purchase
    Request
    StorageLocation
    Transfer
    Vendor
  ).map(&:freeze).freeze

  def initialize(organization, type, filter_conditions = {})
    @current_organization = organization
    @type = type
    @filter_conditions = filter_conditions
  end

  def as_csv
    return nil unless current_organization.present? && type.present?
    return nil unless SUPPORTED_TYPES.include? type

    generate_csv(data_to_export)
  end

  private

  attr_reader :current_organization, :type, :filter_conditions

  def model_class
    @model_class ||= type.constantize
  end

  def generate_csv(data)
    CSV.generate(headers: true) do |csv|
      model_class.csv_export(data).each do |row|
        csv << row
      end
    end
  end

  def data_to_export
    @data_to_export ||= begin
      data = model_class.for_csv_export(current_organization)
      data = filter_data(data) if filter_conditions.present?
      data
    end
  end

  def filter_data(data)
    filtered_data = data
    filter_conditions.each do |field, value|
      next unless respond_to?("filter_by_#{field}", true)

      filtered_data = send("filter_by_#{field}", data, value)
    end
    filtered_data
  end

  def filter_by_date_range(data, value)
    start_date, end_date = value.split(" - ").map { |d| Date.strptime(d, "%m/%d/%Y") }
    data.where(created_at: (start_date.beginning_of_day)..(end_date.end_of_day))
  end
end
