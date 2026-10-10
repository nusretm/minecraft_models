# Minecraft Models

MTM Launcher ve MTN Minecraft Tools projelerinin ortak kullanacağı Minecraft
modellerini ve veri tanımlarını tek bir yerde tutan projedir.

## Amaç

İki uygulamanın aynı kavramları tutarlı biçimde temsil etmesini sağlamak.
Paylaşılan model ve tanımların bu projede merkezi olarak geliştirilmesi,
uygulamalar arasında yinelenen kodu ve zamanla oluşabilecek uyumsuzlukları
azaltır.

## Kapsam

Bu proje, iki uygulamanın birlikte kullanabileceği ortak veri modellerini
içerecektir. Örneğin, ihtiyaçlar netleştikçe Minecraft sürümleri, modlar,
profiller veya araçların paylaştığı diğer alanlar için modeller burada
tanımlanabilir.

Uygulamaya özel arayüz, iş akışı ve iş mantığı bu projenin kapsamı dışındadır;
bu davranışlar ilgili uygulamalarda kalmalıdır.

## Tasarım ilkeleri

- Ortak bir kavramın tek ve tutarlı bir tanımı olmalıdır.
- Modeller, tüketici uygulamaların belirli bir arayüzüne veya iş akışına
  bağımlı olmamalıdır.
- Model değişiklikleri MTM Launcher ve MTN Minecraft Tools ile uyumluluk
  gözetilerek yapılmalıdır.
- Bir modelin anlamı ve alanları, kullanıldığı yerde açık ve anlaşılır
  olmalıdır.

## Kullanım

Paketin tek public API giriş noktası kullanılır. `MtnMinecraftGameLoaderVersionList` somut bir sınıftır; loader türüne göre dahili helper seçer. Cache ve metadata hataları kullanılabilir veriyi kaybettirmez:

```dart
import 'package:minecraft_models/minecraft_models.dart';
```

Güncel public API Minecraft sürüm tipi ve loader build channel enum'larını,
immutable loader build modelini ve somut `MtnMinecraftGameLoaderVersionList` sınıfını içerir. Loader build modeli exact upstream version ve URL
değerlerini değiştirmeden saklar. Genel VersionList, provider override sonuçlarını
ve best-effort cache'i yönetir. Loader'a özel JSON/XML parsing ise provider sınıflarındadır.
Mevcut `MtnMinecraftGameLoaderVersion`
modelinde SHA-1 alanı yoktur; kaynak doğrulama ve oyun kurulumu burada yapılmaz.

### Hata yönetimi

`MtnMinecraftError`, cache ve download sorunlarını sayısal olarak gruplar.
`MtnMinecraftGameLoaderVersionList.error` tipli hata değeridir;
`errorCode` aynı enum'un `.code` değerini verir. `errorMessage` ayrıntıyı,
HTTP yanıt kodu gerekiyorsa `errorMessage` içinden okunabilir. Başarılı işlemler
`MtnMinecraftError.none` durumuna döner. Cache ve indirme sorunları kullanılabilir
liste verisini otomatik olarak geçersiz kılmaz.

### Ortak Minecraft loader kimliği

`MtnMinecraftLoaderType` bu paketin public enum'udur ve `MtnLauncher` tarafından
aynı tip olarak kullanılmalıdır; ikinci bir loader type enum'u oluşturulmaz.

```dart
final loaderType = MtnMinecraftLoaderType.fromName(' FABRIC ');
// loaderType == MtnMinecraftLoaderType.fabric

final loaderName = loaderType?.name; // 'fabric'
final unsupported = MtnMinecraftLoaderType.fromName('unknown-loader'); // null
```

`fromName(String?)` bilinmeyen, boş veya null değeri `null` olarak döndürür.
Yanlış bir kimlik hiçbir zaman otomatik olarak `vanilla` yapılmaz. `.name`
Dart enum'unun kendi özelliğidir; ayrıca `toName` gerekmez. Cache dosya isimleri
`loaderType.name` üzerinden oluşturulduğundan önceki `fabric.json`,
`forge.json` vb. dosyalarla eşleşir.

### Dahili loader helper'ları

`MtnMinecraftGameLoaderVersionList` tek public giriş noktasıdır.
`loaderType` parametresine göre Vanilla, Fabric, Forge, NeoForge veya Quilt
helper'ını kendisi oluşturur. Helper'lar `MtnMinecraftGameLoaderVersionListHelper`
sınıfından türetilir. Helper ve beş provider sınıfı, paket barrel export'una
dahil değildir. Provider'ın upstream JSON/XML ayrıştırması ve endpoint'leri
`lib/src/loaders/` altında kalır.



```dart
final cacheDirectory = Directory.systemTemp.path;

var versionListFabric = MtnMinecraftGameLoaderVersionList(
  cacheDirectory: cacheDirectory,
  loaderType: MtnMinecraftLoaderType.fabric,
);

final versions = await versionListFabric.getFromMinecraftVersion('1.21.11');
assert(versionListFabric.loaderType == MtnMinecraftLoaderType.fabric);
```

İlgili çağrı gerekiyorsa önce genel katalog yüklenir. Dahili helper'lar
`doLoadFromWeb()` ve `doGenerateMinecraftVersionList(mcVersion, types)`
metotlarını override eder; cache, HTTP ve hata durumları ana VersionList'e aittir.
`MtnMinecraftGameLoaderVersion.fromRawData()` eklenmedi. Ham veri yorumlama
ve loader'a özgü dönüşüm provider sorumluluğudur.

### Beş provider'lı gerçek metadata örneği

```powershell
dart run example/game_loader_version_lists.dart 1.21.11
```

Örneğin `main()` metodu Vanilla, Fabric, Quilt, Forge ve NeoForge için
beş `MtnMinecraftGameLoaderVersionList` nesnesi oluşturur; her birinin
`loaderType` değeri farklıdır. Cache işletim sisteminin geçici klasörü
altındadır; uygulamanın callback veya provider sınıfı tanımlaması gerekmez.

Vanilla helper'ı Mojang manifest index'ini okur. Fabric ve Quilt helper'larının
`doLoadFromWeb()` metotları desteklenen **Minecraft sürümü index kayıtlarını** tutar;
bu kayıtların `version` alanı oyun sürümü kimliğidir, loader build değildir.
Seçilen oyun için gerçek loader build ve JSON profile URL'leri
`doGenerateMinecraftVersionList()` içerisinde elde edilir.

Forge ve NeoForge sürümleri Maven metadata üzerinden ayrıştırılır. Onların
`url` alanları JSON manifest değil, **installer JAR** kaynağıdır.
Bu örnek kurulum, SHA-1 doğrulaması veya oyun çalıştırması yapmaz.
Maven metadata'nın sayısal sürüm sıralaması yayın tarihi garantisi vermez;
üretim ortamında "en yeni" kararı için sağlayıcı yayın bilgisinin teyidi gerekir.

## Proje durumu

PR #6'nın eski concrete-provider sözleşmesi Windows'ta doğrulandı ve `main`e
merge edildi (40/40 test). Güncel helper refaktörü ayrı feature branch'tedir;
yeni sözleşmenin analyzer/test ve canlı smoke doğrulaması henüz yapılmadı.
Tüketici repository entegrasyonları ayrı checkpoint'lerdir.
