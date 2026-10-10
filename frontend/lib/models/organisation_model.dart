import 'dart:convert';

List<OrganisationModel> organisationFromJson(String str) => List<OrganisationModel>.from(json.decode(str).map((x) => OrganisationModel.fromJson(x)));

String organisationToJson(List<OrganisationModel> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class OrganisationModel {
    final int organizationId;
    final String name;
    final int memberCount;
    final bool canManage;

    OrganisationModel({
        required this.organizationId,
        required this.name,
        required this.memberCount,
        required this.canManage,
    });

    factory OrganisationModel.fromJson(Map<String, dynamic> json) => OrganisationModel(
        organizationId: json["organizationId"],
        name: json["name"],
        memberCount: json["memberCount"],
        canManage: json["canManage"],
    );

    Map<String, dynamic> toJson() => {
        "organizationId": organizationId,
        "name": name,
        "memberCount": memberCount,
        "canManage": canManage,
    };
}
