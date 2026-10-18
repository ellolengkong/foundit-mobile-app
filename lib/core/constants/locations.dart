/// Campus location hierarchy from DATA_MODEL.md §5.3.
///
/// **IMPORTANT — EXAMPLE DATA:**
/// Building names below are *example placeholders*. They have NOT been verified
/// against official UNSRAT facilities. Replace with confirmed names before
/// shipping. Faculty/area names are commonly known but should still be checked
/// with the team.
library;

/// Ordered list of campus areas / faculties.
///
/// Includes the special entries required by the PRD:
/// - "Area Umum Kampus"
/// - "Lainnya"
/// - "Tidak tahu lokasi persis" (mapped to "Tidak tahu")
const List<String> kCampusAreas = [
  'Fakultas Kedokteran',
  'Fakultas Teknik',
  'Fakultas Pertanian',
  'Fakultas Peternakan',
  'Fakultas Perikanan dan Ilmu Kelautan',
  'Fakultas Ekonomi dan Bisnis',
  'Fakultas Hukum',
  'Fakultas Matematika dan Ilmu Pengetahuan Alam',
  'Fakultas Ilmu Sosial dan Politik',
  'Fakultas Ilmu Budaya',
  'Fakultas Kesehatan Masyarakat',
  'Pascasarjana',
  'Area Umum Kampus',
  'Lainnya',
  'Tidak tahu',
];

/// Example building/facility names per campus area.
///
/// ⚠️ These are **unverified example names**. Do not treat them as an
/// official directory. Every list includes "Lainnya" and "Tidak tahu" as
/// fallback options so the user is never stuck.
const Map<String, List<String>> kBuildingsByArea = {
  'Fakultas Kedokteran': [
    'Gedung Kuliah FK',
    'Laboratorium Anatomi',
    'Rumah Sakit Pendidikan',
    'Lainnya',
    'Tidak tahu',
  ],
  'Fakultas Teknik': [
    'Gedung Kuliah Teknik',
    'Lab Komputer Teknik',
    'Workshop Teknik Mesin',
    'Lainnya',
    'Tidak tahu',
  ],
  'Fakultas Pertanian': [
    'Gedung Kuliah Pertanian',
    'Laboratorium Pertanian',
    'Lainnya',
    'Tidak tahu',
  ],
  'Fakultas Peternakan': [
    'Gedung Kuliah Peternakan',
    'Laboratorium Peternakan',
    'Lainnya',
    'Tidak tahu',
  ],
  'Fakultas Perikanan dan Ilmu Kelautan': [
    'Gedung Kuliah FPIK',
    'Laboratorium Perikanan',
    'Lainnya',
    'Tidak tahu',
  ],
  'Fakultas Ekonomi dan Bisnis': [
    'Gedung Kuliah FEB',
    'Ruang Seminar FEB',
    'Lainnya',
    'Tidak tahu',
  ],
  'Fakultas Hukum': [
    'Gedung Kuliah Hukum',
    'Perpustakaan Hukum',
    'Lainnya',
    'Tidak tahu',
  ],
  'Fakultas Matematika dan Ilmu Pengetahuan Alam': [
    'Gedung Kuliah FMIPA',
    'Lab Komputer FMIPA',
    'Laboratorium Sains',
    'Lainnya',
    'Tidak tahu',
  ],
  'Fakultas Ilmu Sosial dan Politik': [
    'Gedung Kuliah FISIP',
    'Lainnya',
    'Tidak tahu',
  ],
  'Fakultas Ilmu Budaya': ['Gedung Kuliah FIB', 'Lainnya', 'Tidak tahu'],
  'Fakultas Kesehatan Masyarakat': [
    'Gedung Kuliah FKM',
    'Lainnya',
    'Tidak tahu',
  ],
  'Pascasarjana': ['Gedung Pascasarjana', 'Lainnya', 'Tidak tahu'],
  'Area Umum Kampus': [
    'Perpustakaan Pusat',
    'Rektorat',
    'Kantin Pusat',
    'Lapangan Olahraga',
    'Masjid Kampus',
    'Parkiran Utama',
    'Lainnya',
    'Tidak tahu',
  ],
  'Lainnya': ['Lainnya', 'Tidak tahu'],
  'Tidak tahu': ['Tidak tahu'],
};

/// Disclaimer explaining that building names are unverified prototype examples.
const String kBuildingExampleDisclaimer =
    'Daftar gedung merupakan data contoh prototipe dan belum diverifikasi secara resmi dengan pihak kampus UNSRAT.';

/// Returns the building list for a given [area], or a fallback with
/// "Lainnya" and "Tidak tahu" if the area is not in the map.
List<String> buildingsForArea(String area) {
  return kBuildingsByArea[area] ?? const ['Lainnya', 'Tidak tahu'];
}

/// Helper to check if a building name is an unverified sample placeholder.
/// "Lainnya" and "Tidak tahu" are standard fallbacks; specific names are examples.
bool isExampleBuilding(String? building) {
  if (building == null || building.trim().isEmpty) return false;
  final b = building.trim();
  return b != 'Lainnya' && b != 'Tidak tahu';
}
