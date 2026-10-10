import 'dart:convert';

ticketComment welcomeFromJson(String str) => ticketComment.fromJson(json.decode(str));

String welcomeToJson(ticketComment data) => json.encode(data.toJson());

class ticketComment {
    final int idticketComment;
    final int ticketIdticket;
    final int userIduser;
    final DateTime date;
    final String content;

    ticketComment({
        required this.idticketComment,
        required this.ticketIdticket,
        required this.userIduser,
        required this.date,
        required this.content,
    });

    factory ticketComment.fromJson(Map<String, dynamic> json) => ticketComment(
        idticketComment: json["idticketComment"],
        ticketIdticket: json["ticketIdticket"],
        userIduser: json["userIduser"],
        date: DateTime.parse(json["date"]),
        content: json["content"],
    );

    Map<String, dynamic> toJson() => {
        "idticketComment": idticketComment,
        "ticketIdticket": ticketIdticket,
        "userIduser": userIduser,
        "date": "${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}",
        "content": content,
    };
}