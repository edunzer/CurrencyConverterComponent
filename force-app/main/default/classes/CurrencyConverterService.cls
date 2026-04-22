public with sharing class CurrencyConverterService {

    public CurrencyConverterService() {}

    // DTO for currency info
    public class CurrencyInfo {
        @AuraEnabled public String IsoCode;
        @AuraEnabled public String Symbol;
        @AuraEnabled public String Name;
        @AuraEnabled public Decimal ConversionRate;
        @AuraEnabled public Boolean IsActive;
        public CurrencyInfo(String iso, String symbol, String name, Decimal rate, Boolean active) {
            this.IsoCode = iso;
            this.Symbol = symbol;
            this.Name = name;
            this.ConversionRate = rate;
            this.IsActive = active;
        }
    }

    /**
     * Get all active currencies in the org
     */
    @AuraEnabled(cacheable=true)
    public static List<CurrencyInfo> getActiveCurrencies() {
        List<CurrencyInfo> result = new List<CurrencyInfo>();
        for (CurrencyType ct : [SELECT IsoCode, Symbol, ConversionRate, IsActive, DecimalPlaces, CurrencyName FROM CurrencyType WHERE IsActive = true]) {
            result.add(new CurrencyInfo(
                ct.IsoCode,
                ct.Symbol,
                ct.CurrencyName,
                ct.ConversionRate,
                ct.IsActive
            ));
        }
        return result;
    }

    /**
     * Convert an amount from one currency to another using org rates
     * Handles indirect conversion via USD if needed
     */
    @AuraEnabled
    public static Decimal convertCurrency(Decimal amount, String fromIso, String toIso) {
        if (amount == null || fromIso == null || toIso == null) {
            throw new AuraHandledException('Amount and currency codes are required.');
        }
        if (fromIso == toIso) {
            return amount.setScale(2);
        }

        Map<String, CurrencyType> currencyMap = new Map<String, CurrencyType>([
            SELECT IsoCode, ConversionRate, IsActive FROM CurrencyType WHERE IsActive = true
        ]);

        if (!currencyMap.containsKey(fromIso) || !currencyMap.containsKey(toIso)) {
            throw new AuraHandledException('Selected currency is not active or does not exist.');
        }

        Decimal fromRate = currencyMap.get(fromIso).ConversionRate;
        Decimal toRate = currencyMap.get(toIso).ConversionRate;

        // All rates are relative to org base currency (USD)
        // Convert from source to USD, then USD to target
        Decimal usdAmount = amount / fromRate;
        Decimal result = usdAmount * toRate;
        return result.setScale(2);
    }

    /**
     * Get the org's default currency ISO code (assume USD fallback)
     */
    @AuraEnabled(cacheable=true)
    public static String getOrgDefaultCurrencyIso() {
        Organization orgInfo = [SELECT DefaultCurrencyIsoCode FROM Organization LIMIT 1];
        return orgInfo.DefaultCurrencyIsoCode != null ? orgInfo.DefaultCurrencyIsoCode : 'USD';
    }
}