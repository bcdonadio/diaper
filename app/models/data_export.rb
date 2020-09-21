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

  def initialize(organization, type)
    @current_organization = organization
    @type = type
  end

  def as_csv
    return nil unless current_organization.present? && type.present?
    return nil unless SUPPORTED_TYPES.include? type

    data_to_export = model_class.for_csv_export(current_organization)
    generate_csv(data_to_export)
  end

  private

  attr_reader :current_organization, :type

  def generate_csv(data)
    CSV.generate(headers: true) do |csv|
      csv << headers

      data.each do |element|
        csv << element.csv_export_attributes
      end
    end
  end

  def headers
    @headers ||= model_class.csv_export_headers
  end

  def model_class
    @model_class ||= type.constantize
  end
end
