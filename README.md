
# CurrencyConverterComponent

Salesforce Lightning Web Component (LWC) for converting amounts between active org currencies using Salesforce `CurrencyType.ConversionRate` values. Includes a calculator, exchange rate table, swap, and copy features.

## Screenshot

![Component Example](./images/Screenshot%202026-04-29%20172045.png)

![Component Example](./images/Screenshot%202026-04-29%20171633.png)


## Features & How it Works

**UI and logic split across:**
- **LWC:** `force-app/main/default/lwc/currencyConverter`
- **Apex service:** `force-app/main/default/classes/CurrencyConverterService.cls`

### Main Features

- **Currency Calculator Tab:**
  - Select source (**From Currency**) and target (**To Currency**) currencies from active org currencies.
  - Enter an amount to convert.
  - **Swap** button to quickly switch source and target currencies.
  - **Calculate** button performs conversion using Salesforce-configured rates.
  - **Exchange Rate** field shows the calculated rate for the selected pair.
  - **Converted Amount** field displays the result.
  - **Copy** icon copies the converted value to clipboard and briefly shows a "Copied!" message.
  - **Spinner** appears while conversion is in progress.
  - **Error messages** are shown if currency loading or conversion fails.

- **Exchange Rates Tab:**
  - Table lists all active org currencies and their rates relative to the org base currency (USD).
  - Sorted alphabetically by currency code.

### Runtime Flow

1. On load, fetches active currencies (`getActiveCurrencies`).
2. Sets initial **From Currency** to user's default currency if available, otherwise org default (USD fallback).
3. User selects currencies and enters amount.
4. Clicking **Calculate** calls `convertCurrency(amount, fromIso, toIso)`.
5. Result and exchange rate are displayed; user can copy result.
6. Swap icon switches source and target currencies.

### Conversion Formula

Rates are relative to the org base currency:

    baseAmount = amount / fromRate
    result     = baseAmount * toRate

Returned values are rounded to 2 decimal places.


## Component Behavior Details

- **Calculate button is disabled** until:
  - Amount is present, numeric, and greater than 0
  - Both currencies are selected
- **Swap** icon switches source and target currencies instantly
- **Exchange Rate** field shows the calculated rate for the selected pair
- **Copy to clipboard** icon copies the converted value and briefly displays "Copied!"
- **Spinner** appears while conversion is in progress
- **Error messages** are shown for currency load or conversion failures
- **Exchange Rates Table** lists all active org currencies and their rates relative to USD
- **Rate source:** Uses Salesforce-configured conversion rates (**not live market FX rates**)


## Where the Component Can Be Used

Defined in `currencyConverter.js-meta.xml`:

- `lightning__AppPage`
- `lightning__RecordPage`
- `lightning__HomePage`
- `lightning__UtilityBar`

## Notes

- Conversion rates are fixed values configured in Salesforce to align with Finance’s reporting practices for consistency, not live market rates.
- Active system currencies are available for selection. To request a new currency, submit a ticket to Salesforce Support.
