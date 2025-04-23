
import 'package:flutter/material.dart';
import 'package:guild/models/blog_post.dart';

class BlogViewModel extends ChangeNotifier {
  final List<BlogPost> _posts = [];
  List<BlogPost> get posts => _posts;

  void addPost(String title, String content) {
    _posts.add(BlogPost(id: DateTime.now().toString(), title: title, content: content));
    notifyListeners();
  }
}