import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:socialapp/modeller/gonderi.dart';
import 'package:socialapp/modeller/kullanici.dart';
import 'package:socialapp/modeller/yorum.dart';
import 'package:socialapp/servisler/firestoreservisi.dart';
import 'package:socialapp/servisler/yetkilendirmeservisi.dart';
import 'package:timeago/timeago.dart' as timeago;

class Yorumlar extends StatefulWidget {
  final Gonderi gonderi;

  const Yorumlar({Key key, this.gonderi}) : super(key: key);
  @override
  _YorumlarState createState() => _YorumlarState();
}

class _YorumlarState extends State<Yorumlar> {
  @override
  void initState() {
    super.initState();
    timeago.setLocaleMessages('tr', timeago.TrMessages());
  }

  TextEditingController _yorumkontrol = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey[100],
        title: Text(
          "Yorumlar",
          style: TextStyle(color: Colors.black),
        ),
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: <Widget>[
          _yorumlariGoster(),
          yorumEkle(),
        ],
      ),
    );
  }

  _yorumlariGoster() {
    return Expanded(
      child: StreamBuilder<QuerySnapshot>(
        stream: FireStoreServisi().yorumlariGetir(widget.gonderi.id),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          return ListView.builder(
            itemCount: snapshot.data.documents.length,
            itemBuilder: (context, index) {
              Yorum yorum =
                  Yorum.dokumandanuret(snapshot.data.documents[index]);
              return _yorumSatiri(yorum);
            },
          );
        },
      ),
    );
  }

  _yorumSatiri(Yorum yorum) {
    return FutureBuilder<Kullanici>(
        future: FireStoreServisi().kullanicilariGetir(yorum.yayinlayanid),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return SizedBox(
              height: 0.0,
            );
          }
          Kullanici yayinlayan = snapshot.data;
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.grey,
              backgroundImage: NetworkImage(yayinlayan.fotourl),
            ),
            title: RichText(
              text: TextSpan(
                  text: yayinlayan.kullaniciAdi + " ",
                  style: TextStyle(
                      fontSize: 15.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.black),
                  children: [
                    TextSpan(
                      text: yorum.icerik,
                      style: TextStyle(
                        fontWeight: FontWeight.normal,
                        fontSize: 14.0,
                      ),
                    )
                  ]),
            ),
            subtitle: Text(
                timeago.format(yorum.olusturmaZamani.toDate(), locale: "tr")),
          );
        });
  }

  yorumEkle() {
    return ListTile(
      title: TextFormField(
        controller: _yorumkontrol,
        decoration: InputDecoration(
          hintText: "Yorumu Buraya Yazın",
        ),
      ),
      trailing: IconButton(icon: Icon(Icons.send), onPressed: _yorumEkle),
    );
  }

  void _yorumEkle() {
    String aktifKullaniciID =
        Provider.of<YetkilendirmeServisi>(context, listen: false)
            .aktifkullaniciid;
    FireStoreServisi().yorumEkle(
        aktifKullaniciId: aktifKullaniciID,
        gonderi: widget.gonderi,
        icerik: _yorumkontrol.text);
    _yorumkontrol.clear();
  }
}
