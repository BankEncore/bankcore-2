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
  static values = { url: String, initialAccount: Object }

  connect() {
    this.abortController = null
    this.results = []
    this.highlightedIndex = -1
    this.searchTimeout = null
    this.account = this.hasInitialAccountValue ? this.initialAccountValue : null
    this.selectedLabel = this.account?.display_label || this.queryInputTarget.value.trim()
    this.queryInputTarget.value = this.selectedLabel
    this.storeAccount(this.account)
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
      this.storeAccount(null)
      this.dispatch("changed", { detail: { id: "", label: "", account: null } })
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
    this.selectAccount(this.results[Number(option.dataset.accountIndex)])
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
    this.storeAccount(null)
    this.renderResults()
    this.dispatch("changed", { detail: { id: id.toString(), label, account: null } })
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
    if (!account) return

    const accountId = account.id.toString()
    const accountLabel = account.display_label

    this.cancelPendingSearch()
    this.hiddenInputTarget.value = accountId
    this.queryInputTarget.value = accountLabel
    this.queryInputTarget.setCustomValidity("")
    this.selectedLabel = accountLabel
    this.storeAccount(account)
    this.results = []
    this.highlightedIndex = -1
    this.renderResults()
    this.dispatch("changed", { detail: { id: accountId, label: accountLabel, account } })
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
      const ownerName = this.escapeHtml(account.primary_owner_name || "No primary owner")
      const balanceSummary = this.escapeHtml(`${account.available_balance_display} available`)

      return `
        <button
          type="button"
          class="flex w-full items-start justify-between gap-3 px-4 py-3 text-left text-sm hover:bg-base-200 ${activeClasses}"
          data-account-id="${account.id}"
          data-account-index="${index}"
        >
          <span class="min-w-0 flex-1">
            <span class="block ui-mono">${this.escapeHtml(account.display_label)}</span>
            <span class="mt-1 block text-xs text-base-content/65">${ownerName} · ${balanceSummary}</span>
          </span>
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

  storeAccount(account) {
    this.account = account
    this.element.dataset.accountPickerSelectedLabel = account?.display_label || ""
    this.element.dataset.accountPickerAccount = account ? JSON.stringify(account) : ""
  }

  escapeHtml(value) {
    return value
      .toString()
      .replaceAll("&", "&amp;")
      .replaceAll("<", "&lt;")
      .replaceAll(">", "&gt;")
      .replaceAll("\"", "&quot;")
      .replaceAll("'", "&#39;")
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
    "accountContextPanels",
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
      this.accountContextPanelsTarget.innerHTML = this.renderTransferContextPanels(
        this.pickerAccount(this.sourcePickerTarget),
        this.pickerAccount(this.destinationPickerTarget)
      )
      this.guidanceTarget.textContent = "Internal transfer mode. Both accounts must be active and use the same currency."
      return
    }

    this.accountContextPanelsTarget.innerHTML = this.renderSingleContextPanel(this.pickerAccount(this.singlePickerTarget))

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

  pickerAccount(pickerElement) {
    const accountJson = pickerElement?.dataset.accountPickerAccount
    return accountJson ? JSON.parse(accountJson) : null
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

  renderSingleContextPanel(account) {
    return this.renderAccountContextPanel("Selected Account", account, "Waiting for account selection")
  }

  renderTransferContextPanels(sourceAccount, destinationAccount) {
    return `
      <div class="space-y-3">
        ${this.renderAccountContextPanel("From Account", sourceAccount, "Select the source account")}
        ${this.renderAccountContextPanel("To Account", destinationAccount, "Select the destination account")}
      </div>
    `
  }

  renderAccountContextPanel(title, account, emptyText) {
    if (!account) {
      return `
        <section class="rounded-2xl border border-base-300 bg-base-100 p-4">
          <h3 class="text-sm font-semibold uppercase tracking-[0.16em] text-base-content/60">${this.escapeHtml(title)}</h3>
          <p class="mt-1 text-sm text-base-content/60">${this.escapeHtml(emptyText)}</p>
        </section>
      `
    }

    return `
      <section class="rounded-2xl border border-base-300 bg-base-100 p-4">
        <div class="flex items-start justify-between gap-3">
          <div>
            <h3 class="text-sm font-semibold uppercase tracking-[0.16em] text-base-content/60">${this.escapeHtml(title)}</h3>
            <p class="mt-1 text-base font-semibold text-base-content">
              <span class="ui-mono">${this.escapeHtml(account.account_number)}</span>
              <span class="text-base-content/60">·</span>
              ${this.escapeHtml(account.product_name)}
            </p>
          </div>
          <span class="${this.escapeHtml(account.status_class)}">${this.escapeHtml(account.status)}</span>
        </div>
        <div class="mt-4 space-y-3">
          ${this.renderContextRow("Primary Owner", account.primary_owner_name || "—")}
          ${this.renderContextRow("Reference", account.account_reference, "ui-mono")}
          ${this.renderContextRow("Account Type", account.account_type)}
          ${this.renderContextRow("Available Balance", account.available_balance_display, "ui-mono")}
          ${this.renderContextRow("Posted Balance", account.posted_balance_display, "ui-mono")}
          ${this.renderContextRow("Currency", account.currency_code, "ui-mono")}
          ${this.renderContextRow("Branch", account.branch_code || "—")}
        </div>
      </section>
    `
  }

  renderContextRow(label, value, valueClass = "") {
    return `
      <div class="ui-kv-row">
        <div class="ui-kv-label">${this.escapeHtml(label)}</div>
        <div class="ui-kv-value ${valueClass}">${this.escapeHtml(value)}</div>
      </div>
    `
  }

  escapeHtml(value) {
    return (value || "").toString()
      .replaceAll("&", "&amp;")
      .replaceAll("<", "&lt;")
      .replaceAll(">", "&gt;")
      .replaceAll("\"", "&quot;")
      .replaceAll("'", "&#39;")
  }
}

application.register("account-picker", AccountPickerController)
application.register("transaction-workstation", TransactionWorkstationController)
