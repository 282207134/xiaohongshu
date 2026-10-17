class NoteComment {
  final String author, avatar, text;
  NoteComment({required this.author, required this.avatar, required this.text});
  factory NoteComment.fromJson(Map<String, dynamic> j) => NoteComment(
    author: j['author'] as String,
    avatar: j['avatar'] as String,
    text: j['text'] as String,
  );
  Map<String, dynamic> toJson() => {
    'author': author,
    'avatar': avatar,
    'text': text,
  };
}

class Note {
  final String id,
      title,
      body,
      category,
      author,
      authorId,
      avatar,
      location,
      date;
  final List<String> tags, images;
  final List<NoteComment> comments;
  final int likes, saves;
  final double ratio;
  Note({
    required this.id,
    required this.title,
    required this.body,
    required this.category,
    required this.author,
    required this.authorId,
    required this.avatar,
    required this.location,
    required this.date,
    required this.tags,
    required this.images,
    this.comments = const [],
    this.likes = 0,
    this.saves = 0,
    this.ratio = .78,
  });
  factory Note.fromJson(Map<String, dynamic> j) => Note(
    id: j['id'] as String,
    title: j['title'] as String,
    body: j['body'] as String,
    category: j['category'] as String,
    author: j['author'] as String,
    authorId: j['authorId'] as String,
    avatar: j['avatar'] as String,
    location: j['location'] as String,
    date: j['date'] as String,
    tags: List<String>.from(j['tags'] as List),
    images: List<String>.from(j['images'] as List),
    likes: (j['likes'] as num?)?.toInt() ?? 0,
    saves: (j['saves'] as num?)?.toInt() ?? 0,
    ratio: (j['ratio'] as num?)?.toDouble() ?? .78,
    comments: ((j['comments'] as List?) ?? [])
        .map((c) => NoteComment.fromJson(Map<String, dynamic>.from(c as Map)))
        .toList(),
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'body': body,
    'category': category,
    'author': author,
    'authorId': authorId,
    'avatar': avatar,
    'location': location,
    'date': date,
    'tags': tags,
    'images': images,
    'likes': likes,
    'saves': saves,
    'ratio': ratio,
    'comments': comments.map((c) => c.toJson()).toList(),
  };
}

class Product {
  final int id;
  final String title, image;
  final double price;
  Product({
    required this.id,
    required this.title,
    required this.image,
    required this.price,
  });
  factory Product.fromJson(Map<String, dynamic> j) => Product(
    id: j['id'] as int,
    title: j['title'] as String,
    image: j['image'] as String,
    price: (j['price'] as num).toDouble(),
  );
}
