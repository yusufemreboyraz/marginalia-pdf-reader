# Marginalia

macOS için sade, hızlı, kitap-merkezli bir PDF okuyucu. Kişisel kütüphane,
kategoriler, alıntılar ve kenar notları. Tüm veriler yerel —
`~/Library/Application Support/Marginalia/` altında.

## Kurulum & Çalıştırma

```bash
./run.sh             # debug build + .app paketle + aç
./run.sh release     # optimize build (önerilen günlük kullanım için)
./run.sh build       # paketle ama açma
```

İlk çalıştırmadan sonra `Marginalia.app` proje klasörüne çıkar; bunu
`/Applications`'a sürükleyebilirsin.

Gereksinimler: macOS 15+, Swift 6+ (Command Line Tools yeterli, Xcode şart değil).

## Dil

Varsayılan: **English**. Türkçeye geçmek için menü çubuğundan
**Marginalia → Language → Türkçe**. Seçim kalıcıdır.

Yeni bir dil eklemek istersen `Sources/Marginalia/Resources/` altında
yeni bir `xx.lproj/Localizable.strings` dosyası oluştur ve `AppLanguage`
enum'una bir vaka ekle.

## Klavye kısayolları

| Kısayol         | Etki                                     |
|-----------------|------------------------------------------|
| ⌘O              | PDF içe aktar                            |
| ⌘F              | Kütüphanede ara (başlık/yazar/not içeriği) |
| ⌘↵              | Seçili kitabı oku / devam et             |
| ←  →  Space     | Sayfa çevir (okuyucuda)                  |
| ⌘H              | Seçili metnin altını çiz                 |
| ⌘B              | Sayfayı işaretle (bookmark)              |
| ⌘2              | Notlar panelini aç/kapa                  |
| ⌘W              | Okuyucu penceresini kapat                |
| Esc             | Okuyucu penceresini kapat                |
| ⌘D              | Tek sayfa / çift sayfa görünümü (PDF mode) |
| ⌘R              | Reflow / Orijinal PDF moduna geç         |
| ⌘L              | Sonraki temaya geç (Light → Paper → Dark)|
| ⌘⌥1 / ⌘⌥2 / ⌘⌥3 | Light / Paper / Dark teması              |
| ⌘⌥0             | Sistem temasını takip et                 |

## Veriler nerede?

```
~/Library/Application Support/Marginalia/
├── library.json          ← tüm metadata (kitap, not, kategori, puan, ilerleme)
└── Books/                ← içe aktarılan PDF kopyaları
    ├── Borges - Ficciones.pdf
    └── …
```

Yedek almak için bu klasörü kopyala. PDF'leri sil → kitap kütüphaneden gider.

## Mimari (kısa)

- **SPM executable** (`Package.swift`), tek target.
- **SwiftUI + PDFKit + Observation framework** (`@Observable`). SwiftData
  yerine bilinçli olarak `@Observable` + JSON kullanıldı — böylece Xcode
  şart değil, `swift build` Command Line Tools ile yeter.
- **`LibraryStore`** (Models/LibraryStore.swift) ana state. Tüm mutasyonlar
  buradan geçer; değişiklikler 500 ms debounce ile JSON'a kaydedilir.
- **Tema**: `Light / Dark / Paper / System`. Paper ve Dark modlarında PDF
  içeriğinin kendisi de boyanır — `CALayer.filters` üzerinden Core Image
  filtreleri uygulanır (Paper → `CISepiaTone`, Dark → invert + hue shift +
  saturation tweak). Yani PDF'in sarımsı kağıdı, kahverengi mürekkebi
  gerçek bir e-okuyucu gibi gelir; sadece chrome değişmez.
- **Reader ayrı pencerede**: Bir kitabı açmak yeni ve sade bir pencere
  doğurur (`WindowGroup(for: UUID.self)`). Title bar gizli, sidebar yok,
  sadece sayfa. ⌘W veya Esc kapatır. Her kitap kendi penceresinde — aynı
  kitabı ikinci kez açmak mevcut pencereyi öne çıkarır.
- **`PDFViewRepresentable`** Marginalia highlight'larını PDFKit annotation
  olarak render eder; `contents = "Marginalia"` ile kendi annotation'larını
  diğerlerinden ayırır.

## Geliştirme

Tek dosya değiştirip yeniden çalıştırmak için:

```bash
./run.sh
```

Test koşusu yok — bu kişisel bir araç. Şu an V1.0.

## Yol haritası

V1.0 (şimdi) — Solo, local-only: import, kütüphane, okuyucu, alıntı + not,
kategori, durum, puan, tema modları, arama.

V1.1 — Klavye kısayolu paneli (⌘?), Quick Look, daha akıllı kapak çıkarma.

V1.2 — iCloud sync (KVS + Documents).

V2.0 — EPUB desteği + dynamic typography.

V2.5 — AirDrop ile `.marginalia` paylaşımı (PDF + notlar.json).

V3.0 — (opsiyonel) sosyal: arkadaş kitaplığı, ortak raflar.
