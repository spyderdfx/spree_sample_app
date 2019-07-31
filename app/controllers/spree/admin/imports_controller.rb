module Spree
  module Admin
    class ImportsController < Spree::Admin::BaseController
      UPLOAD_PATH = Rails.root.join('public', 'files', 'import').freeze

      def show
        @import = TestApp::Import.new
      end

      def upload
        @import = TestApp::Import.create(import_params)

        TestApp::ImportJob.perform_later(@import.id)

        flash[:success] = I18n.t('controllers.admin.imports.success')
        redirect_back fallback_location: root_path
      end

      private

      def import_params
        params.require(:import).permit(:file)
      end
    end
  end
end
