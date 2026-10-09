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

Paketin tek public API giriş noktası kullanılır:

```dart
import 'package:minecraft_models/minecraft_models.dart';
```

İlk foundation API'si Minecraft sürüm tipini, loader tarafından desteklenen
Minecraft sürümü named record'unu, loader build channel enum'unu ve immutable
loader build modelini içerir. Loader build modeli exact upstream version ve URL
değerlerini değiştirmeden saklar. LVL-I3A kapsamında isteğe bağlı kaynak SHA-1
metadata'sı da JSON üzerinden kayıpsız taşınır; dosya indirimi veya checksum
doğrulaması bu saf value modelinin sorumluluğu değildir.

## Proje durumu

MOD-1 foundation modeli `main` branch'indedir. LVL-I3A kaynak SHA-1 metadata
değişikliği Windows doğrulamasını ve testlerini geçmiştir; commit ve push tamamlanmış,
PR #5 açıktır ve squash merge için ayrı onay beklenmektedir.
Tüketici repository entegrasyonları ayrı checkpoint'lerdir.
