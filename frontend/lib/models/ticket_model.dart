import 'dart:convert';

List<TicketModel> ticketFromJson(String str) => List<TicketModel>.from(json.decode(str).map((x) => TicketModel.fromJson(x)));

String ticketToJson(List<TicketModel> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class TicketModel {
  
    final int? idTicket;
    final int? posterId;
    final String? posterName;
    final int? assigneeId;
    final String? assigneeName;
    final int? organizationId;
    final String? organizationName;
    final int? teamId;
    final String? teamName;
    final String? title;
    final String? description;
    final DateTime? datePosted;
    final DateTime? dateAssigned;
    final DateTime? dateCompleted;
    final String? location;
    final int? pay;
    final String? email;
    final String? status;

    TicketModel({
        this.idTicket,
        this.posterId,
        this.posterName,
        this.assigneeId,
        this.assigneeName,
        this.organizationId,
        this.organizationName,
        this.teamId,
        this.teamName,
        this.title,
        this.description,
        this.datePosted,
        this.dateAssigned,
        this.dateCompleted,
        this.location,
        this.pay,
        this.email,
        this.status,
    });

    factory TicketModel.fromJson(Map<String, dynamic> json) => TicketModel(
        idTicket: json["idTicket"],
        
        posterId: json["posterID"] ?? json["posterId"],
        posterName: json["posterName"],
        assigneeId: json["assigneeID"] ?? json["assigneeId"],
        assigneeName: json["assigneeName"],
        organizationId: json["organizationID"] ?? json["organizationId"],
        organizationName: json["organizationName"],
        teamId: json["teamID"] ?? json["teamId"],
        teamName: json["teamName"],
        title: json["title"],
        description: json["description"],
        
        datePosted: json["datePosted"] != null ? DateTime.tryParse(json["datePosted"]) : null,
        dateAssigned: json["dateAssigned"] != null ? DateTime.tryParse(json["dateAssigned"]) : null,
        dateCompleted: json["dateCompleted"] != null ? DateTime.tryParse(json["dateCompleted"]) : null,
        location: json["location"],
        pay: json["pay"],
        email: json["email"],
        status: json["status"],
    );

    Map<String, dynamic> toJson() => {
        "idTicket": idTicket,
        "posterID": posterId,
        "posterName": posterName,
        "assigneeID": assigneeId,
        "assigneeName": assigneeName,
        "organizationID": organizationId,
        "organizationName": organizationName,
        "teamID": teamId,
        "teamName": teamName,
        "title": title,
        "description": description,
        "datePosted": datePosted?.toIso8601String(),
        "dateAssigned": dateAssigned?.toIso8601String(),
        "dateCompleted": dateCompleted?.toIso8601String(),
        "location": location,
        "pay": pay,
        "email": email,
        "status": status,
    };
}