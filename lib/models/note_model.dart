class Note {
  final int? id;
  final String title;
  final String content;
  final String category;
  final bool isPinned;

  Note({
    this.id,
    required this.title,
    required this.content,
    required this.category,
    this.isPinned = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'category': category,
      'isPinned': isPinned ? 1 : 0,
    };
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'],
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      category: map['category'] ?? 'Kuliah',
      isPinned: map['isPinned'] == 1,
    );
  }
}