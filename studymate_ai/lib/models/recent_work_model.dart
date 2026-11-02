class RecentWork {
  final String id;
  final String title;
  final String subtitle;
  final String badgeText;
  final String statusTag;

  RecentWork({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.badgeText,
    required this.statusTag,
  });

  factory RecentWork.fromJson(Map<String, dynamic> json) {
    return RecentWork(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      subtitle: json['subtitle'] ?? '',
      badgeText: json['badge_text'] ?? 'DOC',
      statusTag: json['status_tag'] ?? 'Completed',
    );
  }
}
