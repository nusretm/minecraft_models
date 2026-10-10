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

Paketin tek public API giriş noktası kullanılır. `MtnMinecraftGameLoaderVersionList` ortak base sınıftır; beş hazır provider sınıfı loader sürüm indeksini sunar, cache ve metadata hataları kullanılabilir veriyi kaybettirmez:

```dart
import 'package:minecraft_models/minecraft_models.dart';
```

Güncel public API Minecraft sürüm tipi ve loader build channel enum'larını,
immutable loader build modelini ve abstract `MtnMinecraftGameLoaderVersionList` ile beş provider sınıfını içerir. Loader build modeli exact upstream version ve URL
değerlerini değiştirmeden saklar. Genel VersionList ise loader'a özel JSON formatlarını bilmeden
callback sonuçlarını ve best-effort cache'i yönetir. Mevcut `MtnMinecraftGameLoaderVersion`
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

### Yerleşik VersionList provider sınıfları

Bu pakette `MtnMinecraftGameLoaderVersionList` ortak abstract temel sınıftır.
Provider'a özel JSON/XML ayrıştırma, endpoint'ler ve sürüm eşleştirme
`lib/src/loaders/` altında Vanilla, Fabric, Quilt, Forge ve NeoForge
sınıflarındadır. Uygulamalar callback, `loaderType` veya parser tanımlamak
zorunda değildir; her provider kendi enum değerini sabitler:

```dart
final cacheDirectory = Directory.systemTemp.path;

var versionListVanilla = MtnMinecraftGameLoaderVersionListVanilla(cacheDirectory: cacheDirectory);
var versionListFabric = MtnMinecraftGameLoaderVersionListFabric(cacheDirectory: cacheDirectory);
var versionListQuilt = MtnMinecraftGameLoaderVersionListQuilt(cacheDirectory: cacheDirectory);
var versionListForge = MtnMinecraftGameLoaderVersionListForge(cacheDirectory: cacheDirectory);
var versionListNeoForge = MtnMinecraftGameLoaderVersionListNeoForge(cacheDirectory: cacheDirectory);

final versions = await versionListFabric.getFromMinecraftVersion('1.21.11');
assert(versionListFabric.loaderType == MtnMinecraftLoaderType.fabric);
```

İlgili çağrı gerekiyorsa önce genel katalogu yükler. Her provider `doLoadFromWeb()`
ve `doGenerateMinecraftVersionList(mcVersion, types)` metodlarını override eder;
bunlar artık public constructor callback parametresi değildir.
`MtnMinecraftGameLoaderVersion.fromRawData()` eklenmedi. Ham veri yorumlama
ve loader'a özgü dönüşüm provider sorumluluğudur.

### Beş provider'lı gerçek metadata örneği

```powershell
dart run example/game_loader_version_lists.dart 1.21.11
```

Örneğin `main()` metodu Vanilla, Fabric, Quilt, Forge ve NeoForge'un beş
hazır sınıfını oluşturur. Cache işletim sisteminin geçici klasörü altındadır;
uygulamanın callback tanımlaması gerekmez.

Vanilla Mojang manifest index'ini okur. Fabric ve Quilt'in `doLoadFromWeb()`
metotları desteklenen **Minecraft sürümü index kayıtlarını** tutar;
bu kayıtların `version` alanı oyun sürümü kimliğidir, loader build değildir.
Seçilen oyun için gerçek loader build ve JSON profile URL'leri
`doGenerateMinecraftVersionList()` içerisinde elde edilir.

Forge ve NeoForge sürümleri Maven metadata üzerinden ayrıştırılır. Onların
`url` alanları JSON manifest değil, **installer JAR** kaynağıdır.
Bu örnek kurulum, SHA-1 doğrulaması veya oyun çalıştırması yapmaz.
Maven metadata'nın sayısal sürüm sıralaması yayın tarihi garantisi vermez;
üretim ortamında "en yeni" kararı için sağlayıcı yayın bilgisinin teyidi gerekir.

## Proje durumu

MOD-1 foundation modelleri `main` branch'indedir. VersionList dayanıklılık düzeltmeleri
ayrı bir feature branch'te incelenmektedir; Windows testleri ve merge onayı beklenmektedir.
Tüketici repository entegrasyonları ayrı checkpoint'lerdir.
