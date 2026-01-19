class Message {
  final int id;
  final String message;
  final int sura;
  final int ajet;
  final String imagePath;
  final String description;

  Message({
    required this.id,
    required this.message,
    required this.sura,
    required this.ajet,
    required this.imagePath,
    this.description = '',
  });

  factory Message.fromCsv(List<dynamic> row) {
    return Message(
      id: int.parse(row[0].toString()),
      message: row[1].toString(),
      sura: int.parse(row[2].toString()),
      ajet: int.parse(row[3].toString()),
      imagePath: row[4].toString(),
      description: row.length > 5 ? row[5].toString() : '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'message': message,
      'sura': sura,
      'ajet': ajet,
      'imagePath': imagePath,
      'description': description,
    };
  }

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      message: json['message'],
      sura: json['sura'],
      ajet: json['ajet'],
      imagePath: json['imagePath'],
      description: json['description'] ?? '',
    );
  }
}
