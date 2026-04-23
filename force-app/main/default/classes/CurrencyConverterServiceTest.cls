@isTest
public with sharing class CurrencyConverterServiceTest {

    @isTest
    static void testGetActiveCurrencies() {
        Test.startTest();
        List<CurrencyConverterService.CurrencyInfo> result = CurrencyConverterService.getActiveCurrencies();
        Test.stopTest();
        System.assert(result.size() > 0, 'Should return at least one active currency');
        for (CurrencyConverterService.CurrencyInfo info : result) {
            System.assert(info.IsActive, 'Currency should be active');
        }
    }

    @isTest
    static void testConvertCurrency_Success() {
        // Get at least two active currencies
        List<CurrencyType> activeCurrencies = [SELECT IsoCode, ConversionRate FROM CurrencyType WHERE IsActive = true LIMIT 2];
        if (activeCurrencies.size() < 2) {
            System.assert(false, 'Need at least two active currencies in the org for this test.');
        }
        CurrencyType fromCur = activeCurrencies[0];
        CurrencyType toCur = activeCurrencies[1];
        Decimal amount = 100;
        // Calculate expected conversion
        Decimal usdAmount = amount / fromCur.ConversionRate;
        Decimal expected = (usdAmount * toCur.ConversionRate).setScale(2);
        Decimal actual = CurrencyConverterService.convertCurrency(amount, fromCur.IsoCode, toCur.IsoCode);
        System.assertEquals(expected, actual, 'Conversion should match expected value.');
        // Same currency
        Decimal same = CurrencyConverterService.convertCurrency(amount, fromCur.IsoCode, fromCur.IsoCode);
        System.assertEquals(amount.setScale(2), same, 'Same currency should return original amount');
    }

    @isTest
    static void testGetOrgDefaultCurrencyIso() {
        String iso = CurrencyConverterService.getOrgDefaultCurrencyIso();
        System.assertEquals('USD', iso, 'Default currency should be USD');
    }
}