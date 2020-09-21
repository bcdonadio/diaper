# Provides a pseudo-resource for `DataExport`, a service object that encapsulates exporting functions.
class DataExportsController < ApplicationController
  before_action :validate_export_type

  def csv
    respond_to do |format|
      format.csv { send_data export_data, filename: "#{export_type}-#{Time.zone.today}.csv" }
    end
  end

  private

  def filter_params
    return unless params[:filters]

    params.require(:filters).permit(:date_range)
  end

  def export_type
    @export_type ||= params[:type]
  end

  def export_data
    DataExport.new(current_organization, export_type, filter_params).as_csv
  end

  def validate_export_type
    return if DataExport::SUPPORTED_TYPES.include? export_type
    logger.warn "Export type '#{export_type}' is not supported"
    head :no_content
  end
end
