import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:socialapp/modeller/duyuru.dart';
import 'package:socialapp/modeller/gonderi.dart';
import 'package:socialapp/modeller/kombin.dart';
import 'package:socialapp/modeller/kullanici.dart';
import 'package:socialapp/servisler/storageservis.dart';

class FireStoreServisi {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  int j = 0;
  final zaman = DateTime.now();
  List<String> followers = [];
  List<String> begeniler = [];
  List<String> mesajlar = [];
  List<String> mesajlar2 = [];

  List<String> chatKullanicilari = [];
  Future<void> kullaniciOlustur({id, email, kullaniciAdi, fotoUrl = ""}) async {
    await _firestore.collection("kullanicilar").doc(id).set({
      "kullaniciAdi": kullaniciAdi,
      "email": email,
      "fotoUrl": fotoUrl,
      "hakkinda": "",
      "olusturulmaZamani": zaman
    });
  }

  Future<Kullanici> kullanicilariGetir(id) async {
    DocumentSnapshot doc =
        await _firestore.collection("kullanicilar").doc(id).get();
    if (doc.exists) {
      Kullanici kullanici = Kullanici.dokumandanuret(doc);
      return kullanici;
    }
    return null;
  }

  void kullaniciGuncelle(
      {String kullaniciID,
      String kullaniciAdi,
      String fotoUrl = "",
      String hakkinda}) {
    _firestore.collection("kullanicilar").doc(kullaniciID).update({
      "kullaniciAdi": kullaniciAdi,
      "hakkinda": hakkinda,
      "fotoUrl": fotoUrl
    });
  }

  Future<List<Kullanici>> kullaniciAra(String kelime) async {
    QuerySnapshot snapshot = await _firestore
        .collection("kullanicilar")
        .where("kullaniciAdi", isGreaterThanOrEqualTo: kelime)
        .get();

    List<Kullanici> kullanicilar =
        snapshot.docs.map((doc) => Kullanici.dokumandanuret(doc)).toList();
    return kullanicilar;
  }

  Future<List<Kullanici>> takipciListesi(String kullaniciId) async {
    QuerySnapshot snapshot;
    QuerySnapshot snapshots = await _firestore
        .collection("takipciler")
        .doc(kullaniciId)
        .collection("kullanicininTakipcileri")
        .get();

    followers = snapshots.docs.map((doc) => doc.id).toList();

    //String field = followers[i];
    if (followers.isEmpty) {
      return null;
    }
    snapshot = await _firestore
        .collection("kullanicilar")
        .where(FieldPath.documentId, whereIn: followers)
        .get();

    List<Kullanici> kullanicilar =
        snapshot.docs.map((doc) => Kullanici.dokumandanuret(doc)).toList();
    //print(kullanicilar);
    return kullanicilar;
  }

  Future<List<Kullanici>> takipedilenListesi(String kullaniciId) async {
    QuerySnapshot snapshot;
    QuerySnapshot snapshots = await _firestore
        .collection("takipedilenler")
        .doc(kullaniciId)
        .collection("kullanicininTakipedilenleri")
        .get();

    followers = snapshots.docs.map((doc) => doc.id).toList();

    //String field = followers[i];
    if (followers.isEmpty) {
      return null;
    }
    snapshot = await _firestore
        .collection("kullanicilar")
        .where(FieldPath.documentId, whereIn: followers)
        .get();

    List<Kullanici> kullanicilar =
        snapshot.docs.map((doc) => Kullanici.dokumandanuret(doc)).toList();
    //print(kullanicilar);
    return kullanicilar;
  }

  Future<List<Kullanici>> begeniListesi(String gonderiId) async {
    QuerySnapshot snapshot;
    QuerySnapshot snapshots = await _firestore
        .collection("begeniler")
        .doc(gonderiId)
        .collection("gonderiBegenileri")
        .get();

    begeniler = snapshots.docs.map((doc) => doc.id).toList();

    //String field = followers[i];
    if (begeniler.isEmpty) {
      return null;
    }
    snapshot = await _firestore
        .collection("kullanicilar")
        .where(FieldPath.documentId, whereIn: begeniler)
        .get();

    List<Kullanici> kullanicilar =
        snapshot.docs.map((doc) => Kullanici.dokumandanuret(doc)).toList();
    //print(kullanicilar);
    return kullanicilar;
  }

  void takipEt({String aktifKullaniciId, String profilSahibiId}) {
    _firestore
        .collection("takipciler")
        .doc(profilSahibiId)
        .collection("kullanicininTakipcileri")
        .doc(aktifKullaniciId)
        .set({});
    _firestore
        .collection("takipedilenler")
        .doc(aktifKullaniciId)
        .collection("kullanicininTakipedilenleri")
        .doc(profilSahibiId)
        .set({});

    duyuruEkle(
      aktiviteTipi: "takip",
      aktiviteYapanId: aktifKullaniciId,
      profilSahibiId: profilSahibiId,
    );
  }

  void takipdenCik({String aktifKullaniciId, String profilSahibiId}) {
    _firestore
        .collection("takipciler")
        .doc(profilSahibiId)
        .collection("kullanicininTakipcileri")
        .doc(aktifKullaniciId)
        .get()
        .then((DocumentSnapshot doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });
    _firestore
        .collection("takipedilenler")
        .doc(aktifKullaniciId)
        .collection("kullanicininTakipedilenleri")
        .doc(profilSahibiId)
        .get()
        .then((DocumentSnapshot doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });
  }

  Future<bool> takipKontrol(
      {String aktifKullaniciId, String profilSahibiId}) async {
    DocumentSnapshot doc = await _firestore
        .collection("takipedilenler")
        .doc(aktifKullaniciId)
        .collection("kullanicininTakipedilenleri")
        .doc(profilSahibiId)
        .get();
    if (doc.exists) {
      return true;
    }
    return false;
  }

  Future<int> takipciSayisi(kullaniciID) async {
    QuerySnapshot snapshot = await _firestore
        .collection("takipciler")
        .doc(kullaniciID)
        .collection("kullanicininTakipcileri")
        .get();
    return snapshot.docs.length;
  }

  Future<int> takipEdilenSayisi(kullaniciID) async {
    QuerySnapshot snapshot = await _firestore
        .collection("takipedilenler")
        .doc(kullaniciID)
        .collection("kullanicininTakipedilenleri")
        .get();
    return snapshot.docs.length;
  }

  Future<void> gonderiOlustur(
      {gonderiResmiUrl, aciklama, yayinlayanId, konum}) async {
    await _firestore
        .collection("gonderiler")
        .doc(yayinlayanId)
        .collection("kullanicigonderileri")
        .add({
      "gonderiResmiUrl": gonderiResmiUrl,
      "aciklama": aciklama,
      "yayinlayanId": yayinlayanId,
      "begeniSayisi": 0,
      "konum": konum,
      "olusturmaZamani": zaman,
    });
  }

  Future<void> kombinOlustur({kombinResmiUrl, yayinlayanid, mevsim}) async {
    await _firestore
        .collection("kombinler")
        .doc(yayinlayanid)
        .collection("kullaniciKombinleri")
        .add({
      "kombinResmiUrl": kombinResmiUrl,
      "yayinlayanId": yayinlayanid,
      "mevsim": mevsim,
      "olusturmaZamani": zaman,
    });
  }

  Future<List<Gonderi>> gonderileriGetir(kullaniciID) async {
    QuerySnapshot snapshot = await _firestore
        .collection("gonderiler")
        .doc(kullaniciID)
        .collection("kullanicigonderileri")
        .orderBy("olusturmaZamani", descending: true)
        .get();
    List<Gonderi> gonderiler =
        snapshot.docs.map((doc) => Gonderi.dokumandanuret(doc)).toList();
    return gonderiler;
  }

  Future<List<Gonderi>> akisGonderileriniGetir(kullaniciID) async {
    QuerySnapshot snapshot = await _firestore
        .collection("akislar")
        .doc(kullaniciID)
        .collection("kullaniciAkisGonderileri")
        .orderBy("olusturmaZamani", descending: true)
        .get();
    List<Gonderi> gonderiler =
        snapshot.docs.map((doc) => Gonderi.dokumandanuret(doc)).toList();
    return gonderiler;
  }

  Future<List<Kombin>> akisKombinleriniGetir(kullaniciID) async {
    // var addDt = DateTime.now();
    var saatKurali = DateTime.now().subtract(Duration(hours: 24));
    QuerySnapshot snapshot = await _firestore
        .collection("kombinakislari")
        .doc(kullaniciID)
        .collection("kullaniciAkisKombinleri")
        .where("olusturmaZamani", isGreaterThanOrEqualTo: saatKurali)
        .orderBy("olusturmaZamani", descending: true)
        .get();
    List<Kombin> kombinler =
        snapshot.docs.map((doc) => Kombin.dokumandanuret(doc)).toList();
    return kombinler;
  }

  Future<List<Kombin>> kullaniciKombinleriGetir(kullaniciID) async {
    QuerySnapshot snapshot = await _firestore
        .collection("kombinler")
        .doc(kullaniciID)
        .collection("kullaniciKombinleri")
        .orderBy("olusturmaZamani", descending: true)
        .get();
    List<Kombin> kombinler =
        snapshot.docs.map((doc) => Kombin.dokumandanuret(doc)).toList();
    return kombinler;
  }

  Future<List<Kombin>> kullaniciMevsimlikKombinleriGetir(
      kullaniciID, mevsim) async {
    QuerySnapshot snapshot = await _firestore
        .collection("kombinler")
        .doc(kullaniciID)
        .collection("kullaniciKombinleri")
        .where(
          "mevsim",
          isEqualTo: mevsim,
        )
        .orderBy("olusturmaZamani", descending: true)
        .get();
    List<Kombin> kombinler =
        snapshot.docs.map((doc) => Kombin.dokumandanuret(doc)).toList();
    return kombinler;
  }

  /*Future<List<Kombin>> istenilenAkisKombinleriniGetir(
      kullaniciID, istenilenId) async {
    // var addDt = DateTime.now();
    var saatKurali = DateTime.now().subtract(Duration(hours: 24));
    QuerySnapshot snapshot = await _firestore
        .collection("kombinakislari")
        .document(kullaniciID)
        .collection("kullaniciAkisKombinleri")
        .where("yayinlayanId", isEqualTo: istenilenId)
        .where("olusturmaZamani", isGreaterThanOrEqualTo: saatKurali)
        .get();
    List<Kombin> kombinler =
        snapshot.docs.map((doc) => Kombin.dokumandanuret(doc)).toList();
    return kombinler;
  }*/

  Future<void> gonderiSil({String aktifKullaniciId, Gonderi gonderi}) async {
    _firestore
        .collection("gonderiler")
        .doc(aktifKullaniciId)
        .collection("kullanicigonderileri")
        .doc(gonderi.id)
        .get()
        .then((DocumentSnapshot doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });
    QuerySnapshot yorumlarsnapshot = await _firestore
        .collection("yorumlar")
        .doc(gonderi.id)
        .collection("gonderiYorumlari")
        .get();
    yorumlarsnapshot.docs.forEach((DocumentSnapshot doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });
    QuerySnapshot duyurularSnapshot = await _firestore
        .collection("duyurular")
        .doc(gonderi.yayinlayanId)
        .collection("kullanicininDuyurulari")
        .where("gonderiId", isEqualTo: gonderi.id)
        .get();
    duyurularSnapshot.docs.forEach((DocumentSnapshot doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });
    //Gönderinin Fotoğrafları FB den silinmesi
    StorageServisi().gonderiResmiSil(gonderi.gonderiResmiUrl);
  }

  Future<void> gonderiBegen(Gonderi gonderi, String aktifKullaniciID) async {
    DocumentReference docRef = _firestore
        .collection("gonderiler")
        .doc(gonderi.yayinlayanId)
        .collection("kullanicigonderileri")
        .doc(gonderi.id);
    DocumentSnapshot doc = await docRef.get();
    if (doc.exists) {
      Gonderi gonderi = Gonderi.dokumandanuret(doc);
      int yeniBegeniSayisi = gonderi.begeniSayisi + 1;
      docRef.update({
        "begeniSayisi": yeniBegeniSayisi,
      });
      _firestore
          .collection("begeniler")
          .doc(gonderi.id)
          .collection("gonderiBegenileri")
          .doc(aktifKullaniciID)
          .set({});
    }
    //beğen notificationu
    duyuruEkle(
      aktiviteTipi: "beğeni",
      aktiviteYapanId: aktifKullaniciID,
      gonderi: gonderi,
      profilSahibiId: gonderi.yayinlayanId,
    );
  }

  Future<void> gonderiBegenKaldir(
      Gonderi gonderi, String aktifKullaniciID) async {
    DocumentReference docRef = _firestore
        .collection("gonderiler")
        .doc(gonderi.yayinlayanId)
        .collection("kullanicigonderileri")
        .doc(gonderi.id);
    DocumentSnapshot doc = await docRef.get();
    if (doc.exists) {
      Gonderi gonderi = Gonderi.dokumandanuret(doc);
      int yeniBegeniSayisi = gonderi.begeniSayisi - 1;
      docRef.update({
        "begeniSayisi": yeniBegeniSayisi,
      });
      DocumentSnapshot docBegeni = await _firestore
          .collection("begeniler")
          .doc(gonderi.id)
          .collection("gonderiBegenileri")
          .doc(aktifKullaniciID)
          .get();
      if (docBegeni.exists) {
        docBegeni.reference.delete();
      }
    }
  }

  Future<bool> begeniVarmi(Gonderi gonderi, String aktifKullaniciID) async {
    DocumentSnapshot docBegeni = await _firestore
        .collection("begeniler")
        .doc(gonderi.id)
        .collection("gonderiBegenileri")
        .doc(aktifKullaniciID)
        .get();
    if (docBegeni.exists) {
      return true;
    }
    return false;
  }

  Stream<QuerySnapshot> yorumlariGetir(String gonderiId) {
    return _firestore
        .collection("yorumlar")
        .doc(gonderiId)
        .collection("gonderiYorumlari")
        .orderBy("olusturmaZamani", descending: true)
        .snapshots();
  }

  void yorumEkle({String aktifKullaniciId, Gonderi gonderi, String icerik}) {
    _firestore
        .collection("yorumlar")
        .doc(gonderi.id)
        .collection("gonderiYorumlari")
        .add({
      "icerik": icerik,
      "yayinlayanID": aktifKullaniciId,
      "olusturmaZamani": zaman,
    });

    duyuruEkle(
      aktiviteTipi: "yorum",
      aktiviteYapanId: aktifKullaniciId,
      gonderi: gonderi,
      profilSahibiId: gonderi.yayinlayanId,
      yorum: icerik,
    );
  }

  void duyuruEkle(
      {String aktiviteYapanId,
      String profilSahibiId,
      String aktiviteTipi,
      String yorum,
      Gonderi gonderi}) {
    if (aktiviteYapanId == profilSahibiId) {
      return;
    }
    _firestore
        .collection("duyurular")
        .doc(profilSahibiId)
        .collection("kullanicininDuyurulari")
        .add({
      "aktiviteYapanId": aktiviteYapanId,
      "aktiviteTipi": aktiviteTipi,
      "gonderiId": gonderi?.id,
      "gonderiFoto": gonderi?.gonderiResmiUrl,
      "yorum": yorum,
      "olusturmaZamani": zaman,
    });
  }

  Future<List<Duyuru>> duyurulariGetir(String profilSahibiId) async {
    QuerySnapshot snapshot = await _firestore
        .collection("duyurular")
        .doc(profilSahibiId)
        .collection("kullanicininDuyurulari")
        .orderBy("olusturmaZamani", descending: true)
        .limit(20)
        .get();

    List<Duyuru> duyurular = [];
    snapshot.docs.forEach((DocumentSnapshot doc) {
      Duyuru duyuru = Duyuru.dokumandanuret(doc);
      duyurular.add(duyuru);
    });
    return duyurular;
  }

  Future<Gonderi> tekliGonderiGetir(
      String gonderiId, String gonderiSahibiId) async {
    DocumentSnapshot doc = await _firestore
        .collection("gonderiler")
        .doc(gonderiSahibiId)
        .collection("kullanicigonderileri")
        .doc(gonderiId)
        .get();
    Gonderi gonderi = Gonderi.dokumandanuret(doc);
    return gonderi;
  }

  void mesajEkle(
      {String aktifKullaniciId,
      String alanId,
      String icerik,
      String chatRoomId,
      users}) {
    chatKullanicilari = [aktifKullaniciId, alanId];
    _firestore.collection("chatRooms").doc(chatRoomId).collection("chats").add({
      "gonderenId": aktifKullaniciId,
      "icerik": icerik,
      "olusturmaZamani": zaman,
    });

    /*_firestore.collection("chatRooms").document(chatRoomId).set(users);*/
  }

  chatOdasiOlustur(users, chatRoomId) {
    FirebaseFirestore.instance
        .collection("chatRooms")
        .doc(chatRoomId)
        .set(users)
        .catchError((e) {
      print(e);
    });
  }

  Stream<QuerySnapshot> mesajGoster(
      {String alanId, String aktifKullaniciId, String chatRoomId}) {
    Stream<QuerySnapshot> q1 = _firestore
        .collection("chatRooms")
        .doc(chatRoomId)
        .collection("chats")
        .orderBy("olusturmaZamani", descending: false)
        .snapshots();

    return q1;
  }

  /*getUserChats(String itIsMyName) async {
    return await Firestore.instance
        .collection("chatRooms")
        .where('users', arrayContains: itIsMyName)
        .snapshots();
  }*/

  Future<List<Kullanici>> getUserChats2(String kid) async {
    QuerySnapshot snapshot;
    QuerySnapshot snapshots = await _firestore
        .collection("chatRooms")
        .where('users', arrayContains: kid)
        .get();

    mesajlar =
        snapshots.docs.map((doc) => doc.data()["users"][0].toString()).toList();
    mesajlar2 =
        snapshots.docs.map((doc) => doc.data()["users"][1].toString()).toList();

    for (var i = 0; i < mesajlar.length; i++) {
      if (mesajlar[i] == kid) {
        mesajlar[i] = mesajlar2[i];
      }
    }

    /*if (mesajlar[0] == kid) {
      mesajlar = snapshots.documents
          .map((doc) => doc.data["users"][1].toString())
          .toList();
    }
    if (mesajlar[1] == kid) {
      mesajlar = snapshots.documents
          .map((doc) => doc.data["users"][0].toString())
          .toList();
    }*/
    //String field = followers[i];
    if (mesajlar.isEmpty) {
      return null;
    }
    snapshot = await _firestore
        .collection("kullanicilar")
        .where(FieldPath.documentId, whereIn: mesajlar)
        .get();

    List<Kullanici> kullanicilar =
        snapshot.docs.map((doc) => Kullanici.dokumandanuret(doc)).toList();
    //print(kullanicilar);
    return kullanicilar;
  }

  /*Future<List<Kullanici>> kullaniciChatGetir(userId) async {
    QuerySnapshot snapshot = await _firestore
        .collection("kullanicilar")
        .where(FieldPath.documentId, isEqualTo: userId)
        .get();

    List<Kullanici> kullanicilar =
        snapshot.docs.map((doc) => Kullanici.dokumandanuret(doc)).toList();
    return kullanicilar;
  }*/
}
