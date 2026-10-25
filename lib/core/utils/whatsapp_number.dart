String? normalizeWhatsappNumber(String? raw) {
  if (raw == null) return null;

  var digits = raw.replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) return null;
  if (digits.startsWith('0')) {
    digits = '62${digits.substring(1)}';
  }
  if (digits.length < 10 || digits.length > 15) return null;

  return digits;
}
