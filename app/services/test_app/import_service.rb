require 'csv'

module TestApp
  # Service which creates products from csv file.
  # Creates taxons if needed.
  # Creates stock items with products' quantity.
  #
  # Examples:
  #
  #   service = TestApp::ImportSerivce.new('/path/to/file')
  #   service.call
  class ImportService
    COL_SEPARATOR = ';'.freeze
    PRODUCT_ATTRIBUTES = %w(name description price slug).freeze

    # Public: initialization
    #
    # filename - String, path to csv file
    #
    # Returns ImportService instance
    def initialize(filename)
      @filename = filename
      @taxons = {}
    end

    # Public: run import
    #
    # Returns nothing
    def call
      File.open(@filename, 'r') do |file|
        csv = CSV.parse(file.read, headers: true, col_sep: COL_SEPARATOR)

        csv.each do |row|
          next if row.to_h.values.all?(&:nil?)

          create_product(row)
        end
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
        product = Spree::Product.new
        product.assign_attributes(row.to_h.slice(*PRODUCT_ATTRIBUTES))

        product.taxons << taxon(row['category'])
        product.available_on = row['availability_date']
        product.shipping_category = shipping_category

        product.save!

        stock_location.stock_item(product.master).count_on_hand = row['stock_total'].to_i
        stock_location.save!
      end
    end

    # Private: finds or creates taxon by name, and memoizes it
    #
    # name - String, taxon's name
    #
    # Returns Spree::Taxon instance
    def taxon(name)
      taxon = @taxons['name']

      return taxon if taxon.present?

      taxon = Spree::Taxon.where(name: name).first

      if taxon.present?
        @taxons[name] = taxon
        return taxon
      end

      Spree::Taxon.new(name: name)
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
