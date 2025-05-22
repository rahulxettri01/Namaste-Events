import 'dart:convert';

class NotificationModel {
  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    required this.metadata,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String body;
  final String type;
  bool isRead;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json["id"] ?? "",
      title: json["title"] ?? "",
      body: json["body"] ?? "",
      type: json["type"] ?? "general",
      isRead: json["isRead"] ?? false,
      metadata: json["metadata"] ?? {},
      createdAt: json["createdAt"] != null
          ? DateTime.parse(json["createdAt"])
          : DateTime.now(),
    );
  }
}