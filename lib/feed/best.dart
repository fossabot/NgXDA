import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_custom_tabs/flutter_custom_tabs.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import 'package:ngxda/post.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:transparent_image/transparent_image.dart';
import 'package:ngxda/models.dart';
import 'package:url_launcher/url_launcher.dart' as u;

class BestFeeds extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => new BestState();
}

class BestState extends State<BestFeeds> with AutomaticKeepAliveClientMixin {
  List<Post> posts = [];
  http.Client client;
  var opacity_value = 0.0;
  SharedPreferences prefs;

  void fetchBest() {
    setState(() {
      this.opacity_value = 1.0;
    });
    String uri = 'https://www.xda-developers.com';
    print('Fetching $uri');
    client.get(uri).then((response) {
      var document = parse(response.body);
      var posts = document.getElementsByClassName('tb_widget_posts_big')[0].getElementsByClassName('item');
      var new_posts = [];
      for (var post in posts) {
        Post new_post = new Post(
            post.getElementsByTagName('h4')[0].text.trim(),
            '',
            '',
            post.getElementsByTagName('h4')[0].getElementsByTagName('a')[0].attributes['href'],
            post.getElementsByClassName('thumb_hover')[0].getElementsByTagName('img')[0].attributes['src']
        );
        new_posts.add(new_post);
      }
      setState(() {
        this.posts.addAll(Iterable.castFrom(new_posts));
        this.opacity_value = 0.0;
      });
    });
  }

  @override
  void initState() {
    super.initState();
    client = http.Client();
    SharedPreferences.getInstance().then((pref) {
      this.prefs = pref;
    });
    this.fetchBest();
  }

  @override
  void dispose() {
    client.close();
    super.dispose();
  }

  _launchUrl2(url, context) async {
    try {
      await launch(
        url,
        option: new CustomTabsOption(
          toolbarColor: Theme.of(context).primaryColor,
          enableDefaultShare: true,
          enableUrlBarHiding: true,
          showPageTitle: true,
          animation: new CustomTabsAnimation.slideIn(),
          extraCustomTabs: <String>[
            // ref. https://play.google.com/store/apps/details?id=org.mozilla.firefox
            'org.mozilla.firefox',
            // ref. https://play.google.com/store/apps/details?id=com.microsoft.emmx
            'com.microsoft.emmx',
          ],
        ),
      );
    } catch (e) {
      u.launch(url);
    }
  }

  _launchUrl(Post post) {
    String browser = this.prefs.getString('browser');
    if (browser != null && browser.isNotEmpty && browser.toLowerCase() == 'yes') {
      _launchUrl2(post.link, context);
    } else {
      Navigator.of(context).push(new CupertinoPageRoute(
          maintainState: true,
          builder: (context) => new PostPage(post: post)
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return new ListView.builder(
        itemBuilder: (context, index) {
          if (index == posts.length) {
            return new Opacity(opacity: this.opacity_value, child: new Container(
                padding: EdgeInsets.symmetric(vertical: 6.0),
                child: new Image(
                  image: new AssetImage('asset/static/loading.gif'),
                  width: 35.0,
                  height: 35.0,
                )
            ));
          }
          return new GestureDetector(
            onTap: () {
              _launchUrl(posts[index]);
            },
            child: new Card(
              elevation: 0.6,
              child: new Column(
                children: <Widget>[
                  new ListTile(
                      contentPadding:
                      EdgeInsets.symmetric(vertical: 14.0, horizontal: 8.0),
                      leading: new Hero(tag: posts[index].link, child: FadeInImage.memoryNetwork(placeholder: kTransparentImage,
                        image: posts[index].image,
                        width: 100.0,
                      )),
                      title: new Text(
                        posts[index].title,
                        style: TextStyle(
                            fontWeight: FontWeight.w400, fontSize: 16.0),
                      ),
                      subtitle: new Text(
                        posts[index].author,
                        style: TextStyle(
                            fontWeight: FontWeight.w300, fontSize: 14.0),
                      )),
                ],
              ),
            ),
          );
        },
        itemCount: posts.length+1);
  }

  @override
  bool get wantKeepAlive => true;
}
