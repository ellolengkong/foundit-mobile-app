/// Report-related enums from DATA_MODEL.md §5.
///
/// Three **separate** concepts:
/// - [ReportType]: what kind of report (lost vs. found).
/// - [ReportStatus]: lifecycle state (active vs. resolved).
/// - [ModerationStatus]: admin visibility control (visible vs. hidden).
library;

/// Whether the reporter lost or found an item.
enum ReportType {
  lost('lost', 'Barang Hilang', 'Hilang'),
  found('found', 'Barang Ditemukan', 'Ditemukan');

  const ReportType(this.key, this.label, this.shortLabel);

  /// Database key stored in the `report_type` column.
  final String key;

  /// Full Indonesian label for forms and detail screens.
  final String label;

  /// Short label for chips/cards.
  final String shortLabel;
}

/// Lifecycle status of a report — controlled by the report owner.
enum ReportStatus {
  active('active', 'Aktif'),
  resolved('resolved', 'Selesai');

  const ReportStatus(this.key, this.label);
  final String key;
  final String label;
}

/// Admin-only moderation status — controls public visibility.
enum ModerationStatus {
  visible('visible', 'Terlihat'),
  hidden('hidden', 'Disembunyikan');

  const ModerationStatus(this.key, this.label);
  final String key;
  final String label;
}

/// Reason a user flags a report — from DATA_MODEL.md §4.4.
enum FlagReason {
  spam('spam', 'Spam'),
  falseInformation('false_information', 'Informasi Palsu'),
  inappropriate('inappropriate', 'Tidak Pantas'),
  personalData('personal_data', 'Data Pribadi'),
  other('other', 'Lainnya');

  const FlagReason(this.key, this.label);
  final String key;
  final String label;
}

/// Moderation review status for a reported flag — from DATA_MODEL.md §4.4.
enum FlagReviewStatus {
  open('open', 'Perlu Ditinjau'),
  reviewed('reviewed', 'Ditinjau'),
  dismissed('dismissed', 'Diabaikan');

  const FlagReviewStatus(this.key, this.label);
  final String key;
  final String label;
}
