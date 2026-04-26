// lib/models/news_post.dart
class NewsPost {
  final int id;
  final int ownerId;
  final String text;
  final int date;
  final List<String> photoUrls;
  final List<double> photoAspectRatios; // новое поле
  final List<VideoAttachment> videos;
  final List<PollAttachment> polls;
  final List<LinkAttachment> links;

  NewsPost({
    required this.id,
    required this.ownerId,
    required this.text,
    required this.date,
    this.photoUrls = const [],
    this.photoAspectRatios = const [],
    this.videos = const [],
    this.polls = const [],
    this.links = const [],
  });

  factory NewsPost.fromJson(Map<String, dynamic> json) {
    final List<dynamic> attachmentsJson = json['attachments'] ?? [];
    final List<String> photos = [];
    final List<double> aspectRatios = [];
    final List<VideoAttachment> videos = [];
    final List<PollAttachment> polls = [];
    final List<LinkAttachment> links = [];

    for (var attachmentJson in attachmentsJson) {
      final type = attachmentJson['type'] as String;
      switch (type) {
        case 'photo':
          final photo = attachmentJson['photo'];
          final sizes = photo['sizes'] as List<dynamic>;
          
          // Берём фото максимального размера для URL
          final bestQuality = sizes.lastWhere(
            (s) => s['type'] == 'x',
            orElse: () => sizes.last,
          );
          photos.add(bestQuality['url'] as String);

          // Вычисляем aspect ratio (ширина / высота) по максимальному размеру
          final maxSize = sizes.last;
          final width = (maxSize['width'] as num).toDouble();
          final height = (maxSize['height'] as num).toDouble();
          if (height > 0) {
            aspectRatios.add(width / height);
          } else {
            aspectRatios.add(1.0); // fallback
          }
          break;
        case 'video':
          videos.add(VideoAttachment.fromJson(attachmentJson['video']));
          break;
        case 'poll':
          polls.add(PollAttachment.fromJson(attachmentJson['poll']));
          break;
        case 'link':
          links.add(LinkAttachment.fromJson(attachmentJson['link']));
          break;
      }
    }

    return NewsPost(
      id: json['id'],
      ownerId: json['owner_id'],
      text: json['text'] ?? '',
      date: json['date'],
      photoUrls: photos,
      photoAspectRatios: aspectRatios,
      videos: videos,
      polls: polls,
      links: links,
    );
  }

  String get postUrl => 'https://vk.com/bbplay__tmb?w=wall${ownerId}_$id';
}

// Остальные классы (VideoAttachment, PollAttachment, LinkAttachment, Answer) 
// остаются без изменений, как были в предыдущей версии.
// Я приведу их здесь для полноты, но если они у вас уже есть — просто добавьте поле photoAspectRatios.

class VideoAttachment {
  final int id;
  final int ownerId;
  final String title;
  final int duration;
  final String? accessKey;

  VideoAttachment({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.duration,
    this.accessKey,
  });

  factory VideoAttachment.fromJson(Map<String, dynamic> json) {
    return VideoAttachment(
      id: json['id'],
      ownerId: json['owner_id'],
      title: json['title'] ?? 'Без названия',
      duration: json['duration'] ?? 0,
      accessKey: json['access_key'],
    );
  }

  String get videoUrl {
    final owner = ownerId < 0 ? ownerId : -ownerId;
    return 'https://vk.com/video${owner}_$id${accessKey != null ? '_$accessKey' : ''}';
  }
}

class PollAttachment {
  final int id;
  final int ownerId;
  final String question;
  final List<Answer> answers;
  final int votes;

  PollAttachment({
    required this.id,
    required this.ownerId,
    required this.question,
    required this.answers,
    required this.votes,
  });

  factory PollAttachment.fromJson(Map<String, dynamic> json) {
    final answersJson = json['answers'] as List<dynamic>;
    final answers = answersJson.map((a) => Answer.fromJson(a)).toList();
    return PollAttachment(
      id: json['id'],
      ownerId: json['owner_id'],
      question: json['question'] ?? 'Опрос',
      answers: answers,
      votes: json['votes'] ?? 0,
    );
  }
}

class Answer {
  final int id;
  final String text;
  final int votes;
  final double rate;

  Answer({
    required this.id,
    required this.text,
    required this.votes,
    required this.rate,
  });

  factory Answer.fromJson(Map<String, dynamic> json) {
    return Answer(
      id: json['id'],
      text: json['text'],
      votes: json['votes'],
      rate: json['rate'].toDouble(),
    );
  }
}

class LinkAttachment {
  final String url;
  final String title;
  final String? caption;
  final String? description;

  LinkAttachment({
    required this.url,
    required this.title,
    this.caption,
    this.description,
  });

  factory LinkAttachment.fromJson(Map<String, dynamic> json) {
    return LinkAttachment(
      url: json['url'] ?? '',
      title: json['title'] ?? 'Ссылка',
      caption: json['caption'],
      description: json['description'],
    );
  }
}