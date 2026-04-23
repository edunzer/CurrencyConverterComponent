public with sharing class CurrencyConverterService {

    public CurrencyConverterService() {}

    // DTO for currency info
    public class CurrencyInfo {
        @AuraEnabled public String IsoCode;
        @AuraEnabled public Decimal ConversionRate;
        @AuraEnabled public Boolean IsActive;
        public CurrencyInfo(String iso, Decimal rate, Boolean active) {
            this.IsoCode = iso;
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
        for (CurrencyType ct : [SELECT IsoCode, ConversionRate, IsActive FROM CurrencyType WHERE IsActive = true]) {
            result.add(new CurrencyInfo(
                ct.IsoCode,
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

        Map<String, CurrencyType> currencyMap = new Map<String, CurrencyType>();
        for (CurrencyType ct : [SELECT IsoCode, ConversionRate, IsActive FROM CurrencyType WHERE IsActive = true]) {
            currencyMap.put(ct.IsoCode, ct);
        }

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
        // Fallback to USD, as Organization.DefaultCurrencyIsoCode is not available
        return 'USD';
    }

    /**
     * Get the user's default currency ISO code, fallback to org default if not set
     */
    @AuraEnabled(cacheable=true)
    public static String getUserDefaultCurrencyIso() {
        // Try to get the user's currency (works in multi-currency orgs)
        String userCurrency = null;
        try {
            userCurrency = [SELECT DefaultCurrencyIsoCode FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1].DefaultCurrencyIsoCode;
        } catch (Exception e) {
            // Ignore and fallback
        }
        if (String.isNotBlank(userCurrency)) {
            return userCurrency;
        }
        return getOrgDefaultCurrencyIso();
    }
}