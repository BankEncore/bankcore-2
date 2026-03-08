# frozen_string_literal: true

# Ensure Bankcore constants and enums are loaded at boot (they're referenced by models)
require Rails.root.join("lib/bankcore/constants")
require Rails.root.join("lib/bankcore/enums")
