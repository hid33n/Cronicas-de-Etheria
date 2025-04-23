class BlogPost {
  final String id;
  String title, content;
  DateTime date;

  BlogPost({
    required this.id,
    required this.title,
    required this.content,
    DateTime? date,
  }) : date = date ?? DateTime.now();
}