require 'csv'

module TestApp
  # Service which creates products from csv file.
  # Creates taxons if needed.
  # Creates stock items with products' quantity.
  #
  # Examples:
  #
  #   service = TestApp::ImportSerivce.new(Import.first)
  #   service.call
  class ImportService
    COL_SEPARATOR = ';'.freeze
    PRODUCT_ATTRIBUTES = %w(name description price slug).freeze

    # Public: initialization
    #
    # import_id - Integer, id of Import with attached csv file
    #
    # Returns ImportService instance
    def initialize(import_id)
      @import = TestApp::Import.find(import_id)
      @taxons = {}
    end

    # Public: run import
    #
    # Returns nothing
    def call
      csv = CSV.parse(Paperclip.io_adapters.for(@import.file).read, headers: true, col_sep: COL_SEPARATOR)

      csv.each do |row|
        next if row.to_h.values.all?(&:nil?)

        create_product(row)
      end
    end

    private

    # Private: creates product
    #
    # row - Hash or CSV::Row, product's data
    #
    # Returns nothing
    def create_product(row)
      with_handle_errors do
        ActiveRecord::Base.transaction do
          product = Spree::Product.new
          product.assign_attributes(row.to_h.slice(*PRODUCT_ATTRIBUTES))

          product.taxons << Spree::Taxon.find_or_create_by!(name: row['category'])
          product.available_on = row['availability_date']
          product.shipping_category = shipping_category

          product.save!

          stock_location.stock_item(product.master).count_on_hand = row['stock_total'].to_i
          stock_location.save!
        end
      end
    end

    # Private: default stock location
    #
    # Returns Spree::StockLocation instance
    def stock_location
      @stock_location ||= Spree::StockLocation.where(default: true).first
    end

    # Private: finds or creates shipping category
    #
    # Returns Spree::ShippingCategory instance
    def shipping_category
      @shipping_category ||= Spree::ShippingCategory.find_or_create_by!(name: 'Default')
    end

    # Private: wraps some block and handles errors
    #
    # block - some block to execute
    #
    # Returns nothing
    def with_handle_errors
      yield
    rescue StandardError => e
      logger.error e.message
    end

    # Private: log errors
    #
    # Returns Logger instance
    def logger
      @logger ||= if Rails.env.test?
                    Logger.new(STDOUT)
                  else
                    Logger.new(File.join(Rails.root, 'log', 'import.log'))
                  end
    end
  end
end
