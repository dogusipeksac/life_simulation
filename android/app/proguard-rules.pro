# Flutter Gradle eklentisi bu dosyayı release küçültmesine otomatik ekler.
# google_mobile_ads → play-services-ads WorkManager kullanır; Room veritabanı sınıfı
# yansımayla (WorkDatabase_Impl) oluşturulur ve R8 tarafından silinirse uygulama açılışta çöker.
-keep class * extends androidx.room.RoomDatabase { <init>(); }
-keep class androidx.work.impl.WorkDatabase_Impl { *; }
-keep class androidx.work.impl.** { *; }
