class SupportTicket {
  final String queryId;
  final String orgId;
  final String createdBy;
  final DateTime createdAt;
  final String queryType;
  final String description;
  final String status;
  final String? updatedBy;
  final DateTime? updatedAt;

  SupportTicket({
    required this.queryId,
    required this.orgId,
    required this.createdBy,
    required this.createdAt,
    required this.queryType,
    required this.description,
    required this.status,
    this.updatedBy,
    this.updatedAt,
  });

  factory SupportTicket.fromJson(Map<String, dynamic> json) => SupportTicket(
        queryId: json['query_id'] ?? '',
        orgId: json['org_id'] ?? '',
        createdBy: json['created_by'] ?? 'Unknown',
        createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
        queryType: json['queryType'] ?? 'other',
        description: json['description'] ?? 'No description',
        status: json['status'] ?? 'active',
        updatedBy: json['updated_by'],
        updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
      );

  Map<String, dynamic> toJson() => {
        'query_id': queryId,
        'org_id': orgId,
        'created_by': createdBy,
        'created_at': createdAt.toIso8601String(),
        'queryType': queryType,
        'description': description,
        'status': status,
        'updated_by': updatedBy,
        'updated_at': updatedAt?.toIso8601String(),
      };
}
