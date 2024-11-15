import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'PostDetailPage.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: PostsPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class PostsPage extends StatefulWidget {
  @override
  _PostsPageState createState() => _PostsPageState();
}

class _PostsPageState extends State<PostsPage> {

  List posts = [];
  List<int> readPosts = [];
  Map<int, int> timers = {};

  @override
  void initState() {
    super.initState();
    loadReadPosts();
    fetchPosts();
  }

  Future<void> loadReadPosts() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      readPosts =
          (prefs.getStringList('readPosts') ?? []).map(int.parse).toList();
    });
  }

  Future<void> saveReadPost(int postId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    readPosts.add(postId);
    await prefs.setStringList(
        'readPosts', readPosts.map((e) => e.toString()).toList());
  }

  Future<void> fetchPosts() async {
    final response =
        await http.get(Uri.parse('https://jsonplaceholder.typicode.com/posts'));

    if (response.statusCode == 200) {
      setState(() {
        posts = json.decode(response.body);
        for (var post in posts) {
          timers[post['id']] =
              [10, 20, 25][post['id'] % 3];
        }
      });
    } else {
      throw Exception('Failed to load posts');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Knovator'),
      ),
      body: posts.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: posts.length,
              itemBuilder: (context, index) {
                int postId = posts[index]['id'];
                bool isRead = readPosts.contains(postId);

                return Card(
                  margin: EdgeInsets.all(10),
                  elevation: 5,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isRead ? Colors.white : Colors.yellow[100],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListTile(
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                              child: Text(posts[index]['title'],
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                          Row(
                            children: [
                              TimerIcon(
                                  postId: postId,
                                  duration: timers[postId] ?? 10),
                              if (isRead)
                                Icon(Icons.check_circle, color: Colors.green),
                            ],
                          ),
                        ],
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('User ID: ${posts[index]['userId']}'),

                            SizedBox(height: 8),
                            Text('ID: ${posts[index]['id']}'),

                            SizedBox(height: 8),
                            Text(posts[index]['body']),
                          ],
                        ),
                      ),
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                PostDetailPage(postId: postId),
                          ),
                        );
                        if (!isRead) {
                          saveReadPost(postId);
                          setState(() {});
                        }
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class TimerIcon extends StatefulWidget {
  final int postId;
  final int duration;

  TimerIcon({required this.postId, required this.duration});

  @override
  TimerIconState createState() => TimerIconState();
}

class TimerIconState extends State<TimerIcon> {
  late Timer timer;
  int remainingTime = 0;
  bool isVisible = true;

  @override
  void initState() {
    super.initState();
    remainingTime = widget.duration;
    startTimer();
  }

  void startTimer() {
    timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (remainingTime > 0 && isVisible) {
        setState(() {
          remainingTime--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      remainingTime > 0 ? '$remainingTime s' : 'Done',
      style: TextStyle(color: Colors.grey),
    );
  }
}


