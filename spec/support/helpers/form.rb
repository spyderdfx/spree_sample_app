module Helpers
  module Form
    def submit_form
      find('input[name="commit"]').click
    end
  end
end
