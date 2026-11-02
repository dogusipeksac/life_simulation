# interviews.json kaynağı: python3 tools/interviews_src.py > assets/content/interviews.json
# Cevap: (metin, puan, tepki) ya da (metin, puan, tepki, stat, min, blöf tepkisi).
import json

G = ""
Q = [
    ("g_kendin", G, "Bize biraz kendinden bahseder misin?", [
        ("Kısaca: neyi iyi yaptığımı ve burada neyi öğrenmek istediğimi anlatayım.", 2, "Görüşmeci not alıyor. \"Net, güzel.\""),
        ("Doğduğum günden başlayayım mı?", -1, "Görüşmeci saatine bakıyor."),
        ("İnsanlarla iyi anlaşırım; ekip içinde ortamı toparlayan kişi genelde ben olurum.", 3, "Görüşmeci gülümsüyor; sohbet kendiliğinden akıyor.", "Social", 55, "Söylediğin ile oturuşun birbirini tutmuyor; görüşmeci kısa bir \"hı hı\" ile geçiyor."),
    ]),
    ("g_zayif", G, "En büyük zayıf yönün ne?", [
        ("Bazen fazla titizim ama bunun üzerinde çalışıyorum; örnek vereyim.", 2, "Somut örnek işe yarıyor."),
        ("Hiç zayıf yönüm yok.", -2, "Görüşmeci kaşını kaldırıyor."),
        ("Sabahları pek çalışamam.", -1, "Görüşmeci bir şey not alıyor; iyi bir şey olmadığı belli."),
    ]),
    ("g_neden", G, "Neden bu işi istiyorsun?", [
        ("İlanı okuyunca yapabileceğimi düşündüm; şirketi de araştırdım.", 2, "Araştırman dikkat çekiyor."),
        ("Para lazım, açıkçası.", 0, "Dürüstlüğün takdir ediliyor ama yeterli değil."),
        ("Bu alanda uzun süredir kendimi geliştiriyorum; okuduklarımı uygulamak istiyorum.", 3, "Görüşmeci hangi kaynakları okuduğunu soruyor; rahatça anlatıyorsun.", "Education", 55, "Hangi kaynak diye sorulunca aklına tek bir isim gelmiyor."),
    ]),
    ("g_bes_yil", G, "Beş yıl sonra kendini nerede görüyorsun?", [
        ("Bu ekipte sorumluluk almış, işi öğretebilen biri olarak.", 2, "Uzun vadeli düşünmen hoş karşılanıyor."),
        ("Sizin yerinizde.", 0, "Görüşmeci gülüyor; şakayı mı ciddiyeti mi aldığı belli değil."),
        ("Bilmiyorum, belki başka bir şehirde.", -1, "Görüşmeci kalemi bırakıyor."),
    ]),
    ("g_catisma", G, "Bir iş arkadaşınla anlaşamazsan ne yaparsın?", [
        ("Önce baş başa konuşur, ortak bir yol ararım.", 2, "Olgun bir cevap."),
        ("Hemen yöneticiye giderim.", 0, "Görüşmeci başını sallıyor ama ikna olmuş görünmüyor."),
        ("Kimseyle anlaşamamazlık yaşamam, herkes beni sever.", -1, "Görüşmeci gülümsüyor; inanmadığı belli."),
    ]),
    ("g_soru", G, "Son olarak, bize sormak istediğin bir şey var mı?", [
        ("Ekipte ilk üç ayda benden ne bekliyorsunuz?", 2, "\"Güzel soru\" diyor; anlatırken gözleri parlıyor."),
        ("Yok, teşekkürler.", 0, "Görüşme sessizce bitiyor."),
        ("Ne kadar izin var?", -1, "Görüşmeci bir an duraksıyor."),
    ]),

    ("gas_kalabalik", "Gastronomi ve Ağırlama", "Öğle yoğunluğunda on masa birden sipariş bekliyor. Ne yaparsın?", [
        ("Sırayı not alır, mutfağa tek seferde iletir, her masaya bir dakikalık bilgi veririm.", 3, "Görüşmeci, kendi ilk günlerini hatırlıyor gibi gülümsüyor."),
        ("En yakın masadan başlarım.", 1, "Fena değil, ama düzensiz."),
        ("Panik yapmam ama yavaşlarım.", -1, "Görüşmeci \"burada yavaşlık pahalı\" diyor."),
    ]),
    ("gas_sikayet", "Gastronomi ve Ağırlama", "Müşteri yemeğin soğuk geldiğini söyleyip sesini yükseltiyor.", [
        ("Özür diler, tabağı hemen yeniletir, beklerken bir ikram öneririm.", 3, "\"İşte bu\" diyor görüşmeci."),
        ("Mutfağın hatası olduğunu açıklarım.", -1, "Suçu başkasına atmak hoş karşılanmıyor."),
        ("Sakince dinler, şefe iletirim.", 1, "Doğru ama eksik."),
    ]),
    ("gas_hijyen", "Gastronomi ve Ağırlama", "Çiğ tavuk ile salatayı aynı tezgâhta hazırlamak gerekirse?", [
        ("Ayrı tahta ve bıçak kullanırım; arada tezgâhı dezenfekte ederim.", 3, "Görüşmeci hijyen listesini bile çıkarmadan onaylıyor.", "Education", 35, "Ayrı tahta deyince hangi rengin neye ait olduğunu soruyor; bilmiyorsun."),
        ("Önce salatayı, sonra tavuğu hazırlarım.", 1, "Mantıklı bir sıra, yine de eksik."),
        ("Hızlıca yıkarım, sorun olmaz.", -2, "Görüşmeci yüzünü buruşturuyor."),
    ]),

    ("bil_hata", "Bilim ve Mühendislik", "Projede senin hesap hatan fark edildi, teslim yarın.", [
        ("Hatayı hemen bildirir, düzeltme planını ve yeni süreyi sunarım.", 3, "Sorumluluk almak puan kazandırıyor."),
        ("Kimse fark etmeden gece düzeltirim.", 0, "Görüşmeci \"ya yetişmezse?\" diye soruyor."),
        ("Verinin hatalı geldiğini söylerim.", -2, "Görüşmeci not alıyor; iyi bir not değil."),
    ]),
    ("bil_teknik", "Bilim ve Mühendislik", "Bir ölçüm sürekli beklenenden yüzde beş sapıyor. İlk neye bakarsın?", [
        ("Cihaz kalibrasyonuna ve ölçüm koşullarına; sonra yöntemin kendisine.", 3, "Görüşmeci tahtaya bir diyagram çiziyor, birlikte konuşuyorsunuz.", "Education", 60, "Kalibrasyonun nasıl yapıldığını sorunca cümlen yarıda kalıyor."),
        ("Ölçümü birkaç kez tekrarlarım.", 1, "Başlangıç için makul."),
        ("Beş yüzde çok değil, geçerim.", -2, "Görüşmeci sessizleşiyor."),
    ]),
    ("bil_ekip", "Bilim ve Mühendislik", "Ekipte senden daha deneyimli biri yanlış bir yaklaşımda ısrar ediyor.", [
        ("Verilerle küçük bir deneme önerir, sonucu birlikte değerlendiririz.", 3, "\"Kanıtla konuşmak\" görüşmecinin hoşuna gidiyor."),
        ("Deneyimli olduğu için uyarım.", 0, "Görüşmeci biraz hayal kırıklığına uğruyor."),
        ("Toplantıda herkesin önünde yanıldığını söylerim.", -1, "Görüşmeci \"ekip içinde mi?\" diye soruyor."),
    ]),

    ("sag_hasta", "Sağlık ve Bakım", "Hasta ilacını almak istemiyor ve sana bağırıyor.", [
        ("Sakin kalır, neden korktuğunu sorar, gerekirse ekibe haber veririm.", 3, "Görüşmeci başhemşireye bakıp başıyla onaylıyor.", "Social", 45, "Sakin kalırım diyorsun ama sesin titriyor; görüşmeci bunu fark ediyor."),
        ("İlacı vermeden çıkar, sonra tekrar gelirim.", 1, "Zamanlama bazen işe yarar."),
        ("Zorla veririm, kuralı bu.", -3, "Görüşme orada soğuyor."),
    ]),
    ("sag_vardiya", "Sağlık ve Bakım", "On iki saatlik gece vardiyalarına nasıl dayanırsın?", [
        ("Uyku düzenimi korur, beslenmeme dikkat eder, molaları atlamam.", 2, "Gerçekçi bir cevap.", "Health", 50, "Görüşmeci yorgun görünüp görünmediğini soruyor; dürüstçe cevap veremiyorsun."),
        ("Kahveyle.", 0, "Görüşmeci gülüyor ama not almıyor."),
        ("Bilmiyorum, hiç denemedim ama alışırım.", 1, "Dürüst; deneme süresinde göreceklerini söylüyor."),
    ]),
    ("sag_gizlilik", "Sağlık ve Bakım", "Bir komşun, sizin serviste yatan akrabasının durumunu soruyor.", [
        ("Bilgi veremeyeceğimi nazikçe söyler, doktora yönlendiririm.", 3, "Gizliliğe saygın puan kazandırıyor."),
        ("Genel bir şey söylerim, ayrıntı vermem.", -1, "Görüşmeci \"genel bir şey de bilgidir\" diyor."),
        ("Tanıdık olduğu için anlatırım.", -3, "Görüşmeci dosyayı kapatıyor."),
    ]),

    ("tek_bug", "Teknoloji ve Dijital", "Canlı sistemde hata var, kullanıcılar giriş yapamıyor.", [
        ("Önce son değişikliği geri alırım, sonra kayıtlardan nedeni bulurum.", 3, "Görüşmeci \"önce kanamayı durdur\" diyerek onaylıyor.", "Education", 50, "Geri almayı nasıl yapacağını sorunca terimler karışıyor."),
        ("Hatayı bulana kadar kodu incelerim.", 1, "Doğru ama kullanıcılar bekliyor."),
        ("Mesai bitince bakarım.", -3, "Görüşmeci gülmüyor."),
    ]),
    ("tek_ogrenme", "Teknoloji ve Dijital", "Hiç bilmediğin bir aracı bir haftada öğrenmen gerekiyor.", [
        ("Belgelerine bakar, küçük bir örnek proje yapar, takıldığımda sorarım.", 3, "Görüşmeci bunu her gün yaptıklarını söylüyor."),
        ("Bir kursa yazılırım.", 1, "Olur, ama bir hafta kısa."),
        ("Bilmediğim aracı kullanmam.", -2, "Görüşmeci \"burada her şey değişiyor\" diyor."),
    ]),
    ("tek_veri", "Teknoloji ve Dijital", "Müşterinin kişisel verilerini test için kullanmak gerekirse?", [
        ("Anonimleştirilmiş ya da sahte veri kullanırım.", 3, "Görüşmeci rahatlıyor."),
        ("Sadece ben görürsem sorun yok.", -2, "Görüşmeci hukuk ekibini hatırlatıyor."),
        ("Yöneticime sorarım.", 1, "Güvenli bir cevap."),
    ]),

    ("san_elestiri", "Sanat ve Zanaat", "Emek verdiğin işin sert biçimde eleştirildi.", [
        ("Dinler, haklı olanları ayıklar, bir sonraki taslakta uygularım.", 3, "Görüşmeci portfolyonda bir sayfayı açıp \"şunu nasıl yapardın?\" diyor."),
        ("Sanat zevk meselesi derim.", 0, "Kısmen doğru, ama iş birliği istiyorlar."),
        ("Bir daha o kişiye iş göstermem.", -2, "Görüşmeci gülümsemiyor."),
    ]),
    ("san_teslim", "Sanat ve Zanaat", "Müşteri teslimden bir gün önce her şeyi değiştirmek istiyor.", [
        ("Neyin değişebileceğini, neyin süre gerektirdiğini net bir listeyle sunarım.", 3, "Görüşmeci \"profesyonel\" diye not alıyor."),
        ("Geceyi yapar, hepsini yetiştiririm.", 1, "Fedakâr ama sürdürülebilir değil."),
        ("Reddederim.", -1, "Görüşmeci başka bir yol olup olmadığını soruyor."),
    ]),
    ("san_teknik", "Sanat ve Zanaat", "Bize bir çalışmanın nasıl yapıldığını adım adım anlatır mısın?", [
        ("Malzemeyi, ölçüyü ve her aşamadaki hatayı nasıl düzelttiğimi anlatırım.", 3, "Ellerinle anlatıyorsun; görüşmeci öne eğiliyor.", "Education", 40, "Adımları anlatırken sıra karışıyor; görüşmeci sabırla bekliyor."),
        ("İçimden geldiği gibi yaparım.", 0, "Görüşmeci daha somut bir şey bekliyor."),
        ("Bunu sır olarak saklarım.", -1, "Görüşmeci gülüyor ama ikna olmuyor."),
    ]),

    ("doga_hava", "Deniz, Doğa ve Tarım", "Hava raporu kötüleşiyor; iş zamanında bitmeli.", [
        ("Güvenliği öne alır, işi erteler ve nedenini açıkça yazarım.", 3, "Görüşmeci denizin şakaya gelmediğini biliyor; onaylıyor."),
        ("Hızlanır, havadan önce bitiririm.", 0, "Görüşmeci \"bitmezse?\" diye soruyor."),
        ("Rapor abartıyordur.", -2, "Görüşmeci başını iki yana sallıyor."),
    ]),
    ("doga_beden", "Deniz, Doğa ve Tarım", "İş günde saatlerce açık havada ve ağır yük demek.", [
        ("Bedenen hazırım; ağır işte de düzenli çalışırım.", 2, "Görüşmeci elini sıkıyor; sağlam bir tokalaşma.", "Health", 55, "Merdivenden çıkarken soluğun kesildiğini görüşmeci görmüş."),
        ("Alışırım.", 1, "Belki."),
        ("Ağır işleri başkası yapsa?", -2, "Görüşmeci kahkahayı zor tutuyor."),
    ]),
    ("doga_hasat", "Deniz, Doğa ve Tarım", "Ürünün bir kısmında hastalık gördün.", [
        ("Hasta bitkileri ayırır, uzmana danışır, yayılmayı izlerim.", 3, "Görüşmeci kendi tarlasında yaşadığını anlatıyor.", "Education", 35, "Hastalığın adını sorunca tahmin yürütüyorsun."),
        ("Bütün tarlayı ilaçlarım.", 0, "Pahalı ve gereksiz olabilir."),
        ("Görmezden gelirim, belki geçer.", -2, "Görüşmeci yüzünü buruşturuyor."),
    ]),

    ("tic_musteri", "Ticaret ve Finans", "Müşteri büyük bir indirim istiyor, yoksa rakibe gidecek.", [
        ("İndirim yerine değer katan bir paket önerir, sınırımı bilirim.", 3, "Görüşmeci \"pazarlık bilen biri\" diyor.", "Social", 50, "Pazarlığı canlandırınca ilk teklifte geri adım atıyorsun."),
        ("İstediği indirimi veririm.", -1, "Kâr nereye gidiyor?"),
        ("Gidebilir derim.", 0, "Sert, ama bazen gerekli."),
    ]),
    ("tic_hesap", "Ticaret ve Finans", "Ay sonu kasa 1.250 lira eksik.", [
        ("Günlük kayıtları tek tek karşılaştırır, farkı bulana kadar raporlarım.", 3, "Görüşmeci bir tablo açıp seni sınıyor; hızlısın.", "Education", 50, "Tabloyu açınca formüller karışıyor."),
        ("Cebimden tamamlarım.", -1, "Sorunu gizlemek kabul görmüyor."),
        ("Yöneticiye hemen bildiririm.", 2, "Şeffaflık takdir ediliyor."),
    ]),
    ("tic_risk", "Ticaret ve Finans", "Arkadaşın sana kesin kazandıracak bir yatırım fırsatı fısıldıyor; müşteriye de önerir misin?", [
        ("Hayır; müşterinin risk profiline uymayan hiçbir şeyi önermem.", 3, "Görüşmeci derin bir nefes alıyor; doğru cevap."),
        ("Riskini anlatarak öneririm.", 0, "Görüşmeci kaynağın kim olduğunu soruyor."),
        ("Öneririm, kazanırsak herkes mutlu.", -3, "Görüşmeci uyum biriminden bahsediyor."),
    ]),

    ("huk_kural", "Hukuk ve Kamu", "Bir yakının, sırası gelmeden işini hızlandırmanı istiyor.", [
        ("Kibarca reddeder, doğru süreci anlatırım.", 3, "Görüşmeci dürüstlüğünü not ediyor."),
        ("Bir kereliğine yardım ederim.", -3, "Görüşmeci kalemini bırakıyor."),
        ("Kimseye zarar vermeyecekse bakarım.", -1, "\"Zarar herkese\" diyor görüşmeci."),
    ]),
    ("huk_metin", "Hukuk ve Kamu", "Önüne yirmi sayfalık bir yönetmelik konuyor: \"Bunu bir sayfada özetle.\"", [
        ("Amaç, kapsam, yükümlülükler ve yaptırımlar başlıklarıyla özetlerim.", 3, "Özetin görüşmeciyi şaşırtıyor.", "Education", 60, "Başlıkları sayıyorsun ama yaptırım maddesini atlıyorsun."),
        ("İlk ve son sayfayı okurum.", -1, "Görüşmeci \"en önemli madde ortada\" diyor."),
        ("Zaman verirseniz dikkatlice okurum.", 1, "Dikkatli ama yavaş."),
    ]),
    ("huk_vatandas", "Hukuk ve Kamu", "Öfkeli bir vatandaş gişede sırayı bozuyor.", [
        ("Sakince dinler, sorununu not alır, sırasının ne zaman geleceğini söylerim.", 3, "Görüşmeci gişede çalıştığı yılları anlatıyor.", "Social", 45, "Canlandırmada sesin yükseliyor."),
        ("Güvenliği çağırırım.", 0, "Bazen gerekli, ama ilk adım değil."),
        ("Bağırana iş yapmam.", -2, "Görüşmeci kamu hizmetini hatırlatıyor."),
    ]),

    ("med_kaynak", "Medya ve Edebiyat", "Elinde çarpıcı bir haber var ama tek kaynak.", [
        ("İkinci bir kaynakla doğrulamadan yayımlamam.", 3, "Editör başını sallıyor."),
        ("\"İddia\" diye yayımlarım.", 0, "Editör yüzünü buruşturuyor."),
        ("Hemen yayımlarım; ilk biz olalım.", -2, "Editör eski bir düzeltme metnini hatırlıyor."),
    ]),
    ("med_yazi", "Medya ve Edebiyat", "Şu cümleyi düzelt: \"Toplantıya katılmayanlar ve geç gelenlerin isimleri yazıldı.\"", [
        ("\"Toplantıya katılmayanların ve geç gelenlerin isimleri yazıldı.\"", 3, "Editör kırmızı kalemini bırakıyor; aradığı buydu.", "Education", 55, "Cümleyi düzeltirken başka bir yeri bozuyorsun."),
        ("Bence doğru zaten.", -1, "Editör hafifçe gülümsüyor."),
        ("İki cümleye bölerim.", 1, "İşe yarar, ama sorun hâlâ orada."),
    ]),
    ("med_teslim", "Medya ve Edebiyat", "Yazının teslimine bir saat var, aklında hiç fikir yok.", [
        ("Son üç günün notlarına bakar, en güçlü küçük ayrıntıdan başlarım.", 3, "Editör \"yazar refleksi\" diyor."),
        ("Ek süre isterim.", 0, "Bazen olur, sık olmaz."),
        ("İnternetten bir şey bulup uyarlarım.", -3, "Editör intihal yazılımını hatırlatıyor."),
    ]),

    ("spor_baski", "Spor, Havacılık ve Özel Beceriler", "Kritik anda hata yaptın; herkes sana bakıyor.", [
        ("Nefes alır, bir sonraki harekete odaklanırım; hatayı sonra incelerim.", 3, "Görüşmeci \"soğukkanlılık\" diye not alıyor."),
        ("Hatayı telafi etmek için risk alırım.", 0, "Bazen işe yarar, çoğu zaman yaramaz."),
        ("Moralim bozulur, bir süre toparlanamam.", -1, "Dürüst ama endişe verici."),
    ]),
    ("spor_kondisyon", "Spor, Havacılık ve Özel Beceriler", "Fiziksel testten geçmen gerekiyor: hazır mısın?", [
        ("Hazırım; düzenli antrenman yapıyorum.", 3, "Testi rahat geçiyorsun.", "Health", 65, "Testin yarısında soluk soluğa kalıyorsun."),
        ("Biraz zaman verirseniz hazırlanırım.", 1, "Görüşmeci bir sonraki dönemi hatırlatıyor."),
        ("Test şart mı?", -2, "Görüşmeci cevap vermiyor."),
    ]),
    ("spor_kontrol", "Spor, Havacılık ve Özel Beceriler", "Kontrol listesinde bir madde atlanmış ama zaman çok dar.", [
        ("Listeyi baştan tamamlarım; gecikmeyi bildiririm.", 3, "Görüşmeci \"listeler kan ile yazılır\" diyor."),
        ("O madde önemsizdi, devam ederim.", -3, "Görüşmeci dosyanı kapatıyor."),
        ("Bir arkadaşıma kontrol ettiririm.", 1, "Yardım istemek iyi, ama sorumluluk senin."),
    ]),
]


def answer(a):
    out = {"Text": a[0], "Score": a[1], "Reply": a[2]}
    if len(a) > 3:
        out.update({"Stat": a[3], "Min": a[4], "FailReply": a[5]})
    return out


print(json.dumps([{"Id": i, "Theme": t, "Question": q, "Answers": [answer(a) for a in ans]} for i, t, q, ans in Q], ensure_ascii=False, indent=1))
