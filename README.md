# OpSec — mhv1

Minecraft **1.21.11**, Java **21**, Fabric Loader **0.19.3** için özel OpSec sürümü.
Teslim dosyası: `opsec-mhv1.jar`. Teknik metadata sürümü upstream ile aynı: `1.1.7.1`.

## Değişiklikler

- Mod kimliği `opsec_mhv`. Axiom 6.1.3 içindeki `breaks: opsec` kaydı bu ayrı fork'u hedeflemez; Axiom JAR'ı değiştirilmez.
- Axiom yüklüyken Axiom ve zorunlu / paketlenmiş bağımlılıkları beyaz listeye alınır. CUSTOM modunda listeyi temizlemek bu istisnayı kaldırmaz.
- Axiom yüklüyken vanilla kimliği taklidi devre dışıdır. Eski ayar dosyasında açık olsa bile çalışma sırasında kapalı uygulanır. Sunucu Axiom/Fabric kullanımını görebilir.
- Diğer modlar mevcut OpSec filtreleme kurallarına tabidir. Axiom kaldırılınca standart OpSec ayar davranışı geri gelir.
- Eski `config/opsec.json` ayarları ve `assets/opsec` kaynak ad alanı korunur; Java paketleri / mixin yapılandırması gereksiz yere yeniden adlandırılmaz.
- Orijinal OpSec ile aynı anda yüklenmesi engellenir; iki kopya aynı mixinleri uygulamamalıdır.
- Arayüzde mhv1 etiketi ve Axiom uyumluluğu açıklaması görünür. Orijinal GitHub sürümüne yönelik otomatik güncelleme ve checksum karşılaştırması bu değiştirilmiş sürümde çalıştırılmaz. Teslim JAR'ının SHA-256 değeri yanında verilir.

## Derleme ve test

Java 21 ile `./build.ps1` çalıştır. JAR `dist/opsec-mhv1.jar` altında oluşur.
Doğrudan Gradle komutu: `./gradlew.bat :1.21.11:build --console=plain`.
`tests/run-smoke.ps1` Axiom + Fabric API ile; `-WithoutAxiom` Axiom olmadan; `-FullPack` profilin etkin modlarının kopyasıyla çalışır.
Testler `test-runs` altında ayrı oyun klasörlerinde, sahte çevrimdışı test kimliğiyle çalışır; kullanıcının hesaplarını veya dünyalarını kopyalamaz.
Test yardımcı modu teslim edilen JAR'a dahil değildir.
Doğrulama sonuçları `VALIDATION.md` dosyasında tutulur. Açılış / filtre testleri, tüm Axiom araçlarının çok oyunculu kullanımına ilişkin garanti değildir.

## Kaynak ve lisans

Bu resmi Axiom/OpSec sürümü değildir. Upstream: https://github.com/aurickk/OpSec
Temel: `V1.1.7.1`, commit `d9b69daa5043c698d28a5f3397d7ace527f682b5`.
Asıl geliştirici: Aurick. mhv1 değişiklik tarihi: 12 Ekim 2026.
Lisans: GPL-3.0-only; `LICENSE` korunmuştur. Orijinal açıklama `README.upstream.md` içindedir.
Tam değiştirilmiş kaynak ve derleme dosyaları bu projededir; teslim kaynak arşivi `opsec-mhv1-source.zip` olarak hazırlanır.

