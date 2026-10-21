import 'dart:convert';

class ticketComment {
    final int idticketComment;
    final int ticketId;
    final int posterId;
    final DateTime date;
    final String content;
    final bool ownedByCurUser;
    final String userName;

    ticketComment({
        required this.idticketComment,
        required this.ticketId,
        required this.posterId,
        required this.date,
        required this.content,
        required this.ownedByCurUser,
        required this.userName,
    });

    factory ticketComment.fromJson(Map<String, dynamic> json) {
        return ticketComment(
            idticketComment: json['idticketComment'] as int? ?? 0,
            ticketId: json['ticketId'] as int? ?? 0,
            posterId: json['posterId'] as int? ?? 0,
            date: json['date'] != null ? DateTime.parse(json['date'].toString()) : DateTime.now(),
            content: json['content']?.toString() ?? '',
            ownedByCurUser: json['ownedByCurUser'] as bool? ?? false,
            userName: json['userName']?.toString() ?? 'User',
        );
    }

    Map<String, dynamic> toJson() => {
        "idticketComment": idticketComment,
        "ticketId": ticketId,
        "posterId": posterId,
        "date": date.toIso8601String(),
        "content": content,
        "ownedByCurUser": ownedByCurUser,
        "userName": userName,
    };
}