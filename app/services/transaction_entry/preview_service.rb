# frozen_string_literal: true

module TransactionEntry
  class PreviewService
    def self.preview!(request:)
      Dispatcher.preview!(request: request)
    end
  end
end
