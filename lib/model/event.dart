import 'package:firebase_database/firebase_database.dart';

class EventItem {

  EventItem(
      this.title,
      this.body,
      this.color,
      this.imageUrl,
      this.date,
      this.category,
      this.tag,
      this.link,
      this.location,
      this.contact
      );

  String key;
  String title;
  String body;
  String color;
  String imageUrl;
  String date;
  String category;
  String tag;
  String location;
  String contact;
  String link;

  EventItem.fromSnapshot(DataSnapshot snapshot) :
        key = snapshot.key,
        title = snapshot.value['title'],
        body = snapshot.value['body'],
        color = snapshot.value['color'],
        imageUrl = snapshot.value['imageUrl'],
        date = snapshot.value['date'],
        tag = snapshot.value['tag'],
        category = snapshot.value['category'],
        link = snapshot.value['link'],
        location = snapshot.value['location'],
        contact = snapshot.value['contact'];
}