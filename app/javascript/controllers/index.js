import { Controller } from "@hotwired/stimulus"
import { application } from "controllers/application"
import HelloController from "controllers/hello_controller"

application.register("hello", HelloController)

const SEARCH_DEBOUNCE_MS = 200
const TRANSFER_TYPES = ["XFER_INTERNAL"]
const ADJUSTMENT_TYPES = ["ADJ_CREDIT", "ADJ_DEBIT"]
const FEE_TYPES = ["FEE_POST"]
const ACH_TYPES = ["ACH_CREDIT", "ACH_DEBIT"]

class AccountPickerController extends Controller {
  static targets = ["hiddenInput", "queryInput", "results"]
  static values = { url: String }

  connect() {
    this.abortController = null
    this.results = []
    this.highlightedIndex = -1
    this.searchTimeout = null
    this.selectedLabel = this.queryInputTarget.value.trim()
    this.element.dataset.accountPickerSelectedLabel = this.selectedLabel
  }

  disconnect() {
    this.cancelPendingSearch()
  }

  search() {
    const query = this.queryInputTarget.value.trim()
    this.queryInputTarget.setCustomValidity("")

    if (this.hiddenInputTarget.value && query !== this.selectedLabel) {
      this.hiddenInputTarget.value = ""
      this.selectedLabel = ""
      this.element.dataset.accountPickerSelectedLabel = ""
      this.dispatch("changed", { detail: { id: "", label: "" } })
    }

    if (query.length < 2) {
      this.results = []
      this.highlightedIndex = -1
      this.renderResults()
      return
    }

    clearTimeout(this.searchTimeout)
    this.searchTimeout = window.setTimeout(() => {
      this.performSearch(query)
    }, SEARCH_DEBOUNCE_MS)
  }

  showResults() {
    if (this.results.length > 0 || this.resultsTarget.innerHTML.trim() !== "") {
      this.resultsTarget.classList.remove("hidden")
    }
  }

  hideResults() {
    window.setTimeout(() => {
      if (!this.hiddenInputTarget.value) {
        this.queryInputTarget.value = ""
      } else {
        this.queryInputTarget.value = this.selectedLabel
      }

      this.resultsTarget.classList.add("hidden")
    }, 150)
  }

  handleKeydown(event) {
    if (this.resultsTarget.classList.contains("hidden")) return

    switch (event.key) {
    case "ArrowDown":
      event.preventDefault()
      this.highlightResult(this.highlightedIndex + 1)
      break
    case "ArrowUp":
      event.preventDefault()
      this.highlightResult(this.highlightedIndex - 1)
      break
    case "Enter":
      if (this.highlightedIndex >= 0 && this.results[this.highlightedIndex]) {
        event.preventDefault()
        this.selectAccount(this.results[this.highlightedIndex])
      }
      break
    case "Escape":
      event.preventDefault()
      this.resultsTarget.classList.add("hidden")
      break
    }
  }

  choose(event) {
    const option = event.target.closest("[data-account-id]")
    if (!option) return

    event.preventDefault()
    this.selectAccount({
      id: option.dataset.accountId,
      display_label: option.dataset.accountLabel
    })
  }

  preventBlur(event) {
    if (!event.target.closest("[data-account-id]")) return

    event.preventDefault()
  }

  reset(event) {
    const { id = "", label = "" } = event.detail || {}

    this.cancelPendingSearch()
    this.results = []
    this.highlightedIndex = -1
    this.hiddenInputTarget.value = id
    this.queryInputTarget.value = label
    this.queryInputTarget.setCustomValidity("")
    this.selectedLabel = label
    this.element.dataset.accountPickerSelectedLabel = label
    this.renderResults()
    this.dispatch("changed", { detail: { id: id.toString(), label } })
  }

  async performSearch(query) {
    this.cancelPendingSearch()
    this.abortController = new AbortController()

    try {
      const response = await fetch(`${this.urlValue}?q=${encodeURIComponent(query)}`, {
        headers: { Accept: "application/json" },
        signal: this.abortController.signal
      })

      if (!response.ok) {
        throw new Error(`Lookup failed with status ${response.status}`)
      }

      const payload = await response.json()
      this.results = payload.accounts || []
      this.highlightedIndex = this.results.length > 0 ? 0 : -1
      this.renderResults()
    } catch (error) {
      if (error.name === "AbortError") return

      this.results = []
      this.highlightedIndex = -1
      this.resultsTarget.innerHTML = "<div class=\"px-4 py-3 text-sm text-error\">Unable to load account matches.</div>"
      this.resultsTarget.classList.remove("hidden")
    }
  }

  selectAccount(account) {
    const accountId = account.id.toString()
    const accountLabel = account.display_label

    this.cancelPendingSearch()
    this.hiddenInputTarget.value = accountId
    this.queryInputTarget.value = accountLabel
    this.queryInputTarget.setCustomValidity("")
    this.selectedLabel = accountLabel
    this.element.dataset.accountPickerSelectedLabel = accountLabel
    this.results = []
    this.highlightedIndex = -1
    this.renderResults()
    this.dispatch("changed", { detail: { id: accountId, label: accountLabel } })
  }

  highlightResult(index) {
    if (this.results.length === 0) return

    const boundedIndex = Math.max(0, Math.min(index, this.results.length - 1))
    this.highlightedIndex = boundedIndex
    this.renderResults()
  }

  renderResults() {
    if (this.queryInputTarget.value.trim().length < 2) {
      this.resultsTarget.innerHTML = ""
      this.resultsTarget.classList.add("hidden")
      return
    }

    if (this.results.length === 0) {
      this.resultsTarget.innerHTML = "<div class=\"px-4 py-3 text-sm text-base-content/70\">No matching active accounts.</div>"
      this.resultsTarget.classList.remove("hidden")
      return
    }

    const optionsMarkup = this.results.map((account, index) => {
      const activeClasses = index === this.highlightedIndex ? "bg-base-200" : ""

      return `
        <button
          type="button"
          class="flex w-full items-start justify-between gap-3 px-4 py-3 text-left text-sm hover:bg-base-200 ${activeClasses}"
          data-account-id="${account.id}"
          data-account-label="${account.display_label}"
        >
          <span class="min-w-0 flex-1 ui-mono">${account.display_label}</span>
        </button>
      `
    }).join("")

    this.resultsTarget.innerHTML = `
      <div data-action="mousedown->account-picker#preventBlur click->account-picker#choose">
        ${optionsMarkup}
      </div>
    `
    this.resultsTarget.classList.remove("hidden")
  }

  cancelPendingSearch() {
    clearTimeout(this.searchTimeout)

    if (this.abortController) {
      this.abortController.abort()
      this.abortController = null
    }
  }
}

class TransactionWorkstationController extends Controller {
  static targets = [
    "typeSelect",
    "accountFields",
    "transferFields",
    "adjustmentFields",
    "feeFields",
    "achFields",
    "amountInput",
    "amountLabel",
    "selectedAccountContext",
    "guidance",
    "feeTypeSelect",
    "achTrace",
    "achEffectiveDate",
    "achBatch",
    "authRef",
    "singlePicker",
    "sourcePicker",
    "destinationPicker"
  ]

  connect() {
    this.updateFields()
  }

  updateFields() {
    const code = this.typeSelectTarget.value
    const isTransfer = TRANSFER_TYPES.includes(code)
    const isAdjustment = ADJUSTMENT_TYPES.includes(code)
    const isFee = FEE_TYPES.includes(code)
    const isAch = ACH_TYPES.includes(code)
    const isAchDebit = code === "ACH_DEBIT"

    this.accountFieldsTarget.classList.toggle("hidden", isTransfer)
    this.transferFieldsTarget.classList.toggle("hidden", !isTransfer)
    this.adjustmentFieldsTarget.classList.toggle("hidden", !isAdjustment)
    this.feeFieldsTarget.classList.toggle("hidden", !isFee)
    this.achFieldsTarget.classList.toggle("hidden", !isAch)

    this.togglePickerRequired(this.singlePickerTarget, !isTransfer)
    this.togglePickerRequired(this.sourcePickerTarget, isTransfer)
    this.togglePickerRequired(this.destinationPickerTarget, isTransfer)
    this.toggleRequired(this.feeTypeSelectTarget, isFee)
    this.toggleRequired(this.achTraceTarget, isAch)
    this.toggleRequired(this.achEffectiveDateTarget, isAch)
    this.toggleRequired(this.achBatchTarget, isAch)
    this.toggleRequired(this.authRefTarget, isAchDebit)

    if (isFee) {
      this.amountLabelTarget.textContent = "Amount Override (USD)"
      this.amountInputTarget.placeholder = "Leave blank to use fee rule/default"
      this.amountInputTarget.removeAttribute("required")
    } else {
      this.amountLabelTarget.textContent = "Amount (USD)"
      this.amountInputTarget.placeholder = "0.00"
      this.amountInputTarget.setAttribute("required", "required")
    }

    if (isTransfer) {
      this.resetPicker(this.singlePickerTarget)
    } else {
      this.resetPicker(this.sourcePickerTarget)
      this.resetPicker(this.destinationPickerTarget)
    }

    if (!isAch) {
      this.achTraceTarget.value = ""
      this.achEffectiveDateTarget.value = ""
      this.achBatchTarget.value = ""
      this.authRefTarget.value = ""
    }

    if (!isFee) {
      this.feeTypeSelectTarget.value = ""
    }

    this.updateContext()
  }

  updateContext() {
    const code = this.typeSelectTarget.value

    if (TRANSFER_TYPES.includes(code)) {
      const sourceLabel = this.pickerLabel(this.sourcePickerTarget)
      const destinationLabel = this.pickerLabel(this.destinationPickerTarget)
      this.selectedAccountContextTarget.textContent = [sourceLabel, destinationLabel].filter(Boolean).join(" → ") || "Select both transfer accounts"
      this.guidanceTarget.textContent = "Internal transfer mode. Both accounts must be active and use the same currency."
      return
    }

    this.selectedAccountContextTarget.textContent = this.pickerLabel(this.singlePickerTarget) || "Waiting for account selection"

    if (ADJUSTMENT_TYPES.includes(code)) {
      this.guidanceTarget.textContent = "Adjustment mode. Reason and reference capture are required before preview or post."
    } else if (FEE_TYPES.includes(code)) {
      this.guidanceTarget.textContent = "Fee mode. The dispatcher will resolve the active fee rule for the selected account product."
    } else if (ACH_TYPES.includes(code)) {
      this.guidanceTarget.textContent = "ACH mode. Trace, effective date, and batch references are captured as structured transaction references."
    } else {
      this.guidanceTarget.textContent = "Choose a transaction code to load the required controls."
    }
  }

  validateForm(event) {
    const code = this.typeSelectTarget.value
    const activePickers = TRANSFER_TYPES.includes(code) ?
      [this.sourcePickerTarget, this.destinationPickerTarget] :
      [this.singlePickerTarget]

    for (const pickerElement of activePickers) {
      if (!this.validatePickerSelection(pickerElement)) {
        event.preventDefault()
        return
      }
    }
  }

  validatePickerSelection(pickerElement) {
    const queryInput = this.pickerQueryInput(pickerElement)
    const hiddenInput = this.pickerHiddenInput(pickerElement)

    if (!queryInput || !hiddenInput || !queryInput.required) return true

    queryInput.setCustomValidity("")

    if (!queryInput.value.trim()) return true

    if (!hiddenInput.value) {
      queryInput.setCustomValidity("Choose an account from the search results.")
      queryInput.reportValidity()
      return false
    }

    return true
  }

  togglePickerRequired(pickerElement, required) {
    const queryInput = this.pickerQueryInput(pickerElement)
    if (!queryInput) return

    this.toggleRequired(queryInput, required)
    queryInput.setCustomValidity("")
  }

  toggleRequired(field, required) {
    if (!field) return

    if (required) {
      field.setAttribute("required", "required")
    } else {
      field.removeAttribute("required")
    }
  }

  pickerLabel(pickerElement) {
    return pickerElement?.dataset.accountPickerSelectedLabel || ""
  }

  pickerHiddenInput(pickerElement) {
    return pickerElement?.querySelector("[data-account-picker-target='hiddenInput']")
  }

  pickerQueryInput(pickerElement) {
    return pickerElement?.querySelector("[data-account-picker-target='queryInput']")
  }

  resetPicker(pickerElement) {
    pickerElement.dispatchEvent(new CustomEvent("account-picker:reset", {
      bubbles: true,
      detail: { id: "", label: "" }
    }))
  }
}

application.register("account-picker", AccountPickerController)
application.register("transaction-workstation", TransactionWorkstationController)
