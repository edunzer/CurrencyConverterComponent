import { LightningElement, wire, track } from 'lwc';
import getActiveCurrencies from '@salesforce/apex/CurrencyConverterService.getActiveCurrencies';
import convertCurrency from '@salesforce/apex/CurrencyConverterService.convertCurrency';
import getOrgDefaultCurrencyIso from '@salesforce/apex/CurrencyConverterService.getOrgDefaultCurrencyIso';
import getUserDefaultCurrencyIso from '@salesforce/apex/CurrencyConverterService.getUserDefaultCurrencyIso';

export default class CurrencyConverter extends LightningElement {
	@track amount = '';
	@track fromCurrency = '';
	@track toCurrency = '';
	@track currencies = [];
	@track result = null;
	@track error = '';
	@track loading = false;
    @track copied = false;

	// Fetch currencies on load
	@wire(getActiveCurrencies)
	wiredCurrencies({ error, data }) {
		if (data) {
			this.currencies = data;
			// Set defaults after currencies load
			if (!this.fromCurrency) {
				getUserDefaultCurrencyIso()
					.then(userIso => {
						this.fromCurrency = userIso;
					})
					.catch(() => {
						// fallback to org default if user default fails
						getOrgDefaultCurrencyIso()
							.then(defaultIso => {
								this.fromCurrency = defaultIso;
							})
							.catch(() => {
								this.fromCurrency = 'USD';
							});
					});
			}
		} else if (error) {
			this.error = 'Failed to load currencies.';
		}
	}

	handleAmountChange(event) {
		this.amount = event.target.value;
		this.result = null;
		this.error = '';
	}

	handleFromChange(event) {
		this.fromCurrency = event.target.value;
		this.result = null;
		this.error = '';
	}

	handleToChange(event) {
		this.toCurrency = event.target.value;
		this.result = null;
		this.error = '';
	}

	handleSwap() {
		const temp = this.fromCurrency;
		this.fromCurrency = this.toCurrency;
		this.toCurrency = temp;
		this.result = null;
		this.error = '';
	}

	get isCalculateDisabled() {
		return !this.amount || isNaN(this.amount) || Number(this.amount) <= 0 || !this.fromCurrency || !this.toCurrency;
	}

	handleCalculate() {
		this.loading = true;
		this.result = null;
		this.error = '';
		convertCurrency({
			amount: Number(this.amount),
			fromIso: this.fromCurrency,
			toIso: this.toCurrency
		})
			.then(res => {
				this.result = {
					from: this.amount,
					fromIso: this.fromCurrency,
					to: res,
					toIso: this.toCurrency
				};
			})
			.catch(e => {
				this.error = e && e.body && e.body.message ? e.body.message : 'Conversion failed.';
			})
			.finally(() => {
				this.loading = false;
			});
	}

	get currencyOptions() {
		return this.currencies
			.slice()
			.sort((a, b) => a.IsoCode.localeCompare(b.IsoCode))
			.map(c => ({ label: c.IsoCode, value: c.IsoCode }));
	}

    get amountOutput() {
		return this.result ? this.result.to : '';
	}

	handleOutputCopy() {
		const value = this.amountOutput;
		if (value !== undefined && value !== null && value !== '') {
			// Copy to clipboard
			const tempInput = document.createElement('input');
			tempInput.value = value;
			document.body.appendChild(tempInput);
			tempInput.select();
			document.execCommand('copy');
			document.body.removeChild(tempInput);
			// Show copied message
			this.copied = true;
			setTimeout(() => {
				this.copied = false;
			}, 2000);
		}
	}
}