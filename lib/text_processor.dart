class TextProcessor {
  Map<String, String> extractFormData(String text) {
    Map<String, String> formData = {};

    // Extract vendor/shop name (only the first word after "vendor" or "shop")
    RegExp vendorRegex = RegExp(r'(?:vendor|shop)\s+([\w]+)', caseSensitive: false);
    var vendorMatch = vendorRegex.firstMatch(text);
    formData["vendor"] = vendorMatch != null ? vendorMatch.group(1)?.trim() ?? "N/A" : "N/A";

    // Extract crop name
    RegExp cropRegex = RegExp(r'crop\s+([\w]+)', caseSensitive: false);
    var cropMatch = cropRegex.firstMatch(text);
    formData["crop"] = cropMatch != null ? cropMatch.group(1)?.trim() ?? "N/A" : "N/A";

    // Extract quantity in kgs/items (supports both numbers and words)
    RegExp kgsRegex = RegExp(r'(\d+|\b(one|two|three|four|five|six|seven|eight|nine|ten)\b)\s?(kg|kgs|items)', caseSensitive: false);
    var kgsMatch = kgsRegex.firstMatch(text);
    formData["kgs_items"] = kgsMatch != null ? kgsMatch.group(1)?.trim() ?? "N/A" : "N/A";

    // Extract cost per kg/item
    RegExp costRegex = RegExp(r'(\d+)\s?(per\s?kg|per\s?item)', caseSensitive: false);
    var costMatch = costRegex.firstMatch(text);
    formData["cost_per_kg_item"] = costMatch != null ? costMatch.group(1)?.trim() ?? "N/A" : "N/A";

    // Extract total bill (supports "₹", "total bill", "rupees", "rs")
    RegExp totalBillRegex = RegExp(r'₹?\s?([\d.]+)\s?(total bill|rupees|rs)?', caseSensitive: false);
    var totalBillMatch = totalBillRegex.firstMatch(text);
    formData["total_bill"] = totalBillMatch != null ? totalBillMatch.group(1)?.trim() ?? "N/A" : "N/A";

    // Extract amount paid (supports multiple phrases)
    RegExp amountPaidRegex = RegExp(r'₹?\s?([\d.]+)\s?(paid|amount paid|rupees|rs)?', caseSensitive: false);
    var amountPaidMatch = amountPaidRegex.firstMatch(text);
    formData["amount_paid"] = amountPaidMatch != null ? amountPaidMatch.group(1)?.trim() ?? "N/A" : "N/A";

    return formData;
  }
}
