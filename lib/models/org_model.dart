class OrgModel {
  String orgId;
  String orgName;
  String orgDesc;
  String location;

  OrgModel({required this.orgId, required this.orgName, required this.orgDesc, required this.location});

  factory OrgModel.fromJson(Map<String, dynamic> json) {
    return OrgModel(
      orgId: json['org_id'],
      orgName: json['orgName'],
      orgDesc: json['orgDesc'],
      location: json['location'] ?? '',
    );
  }
}
