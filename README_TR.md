# NSClear 🧹

**NSClear** kullanılmayan Swift kodunu bulan, gözden geçiren ve güvenli bir şekilde silen interaktif bir CLI aracıdır.

[![Swift](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/Platform-macOS-lightgrey.svg)](https://www.apple.com/macos)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

## ✨ Özellikler

- 🔍 **Akıllı Analiz**: SwiftSyntax ve IndexStoreDB kullanarak declaration'ları ve referanslarını analiz eder
- 🎯 **Entry Point Algılama**: `@main`, SwiftUI.App, UIApplicationMain, public API ve daha fazlasını otomatik algılar
- 🔗 **Reachability Analizi**: Entry point'lerden erişilemeyen kodu tespit eder
- 📊 **Risk Skorlaması**: Her bulgu için risk skoru hesaplar (0-100)
- 🛡️ **Güvenlik Korumaları**: `@objc`, `dynamic`, `@IBAction`, `@IBOutlet` ve diğer özel attribute'ları otomatik korur
- 🎨 **İnteraktif TUI**: Terminal-based kullanıcı arayüzü ile bulguları gözden geçirin
- 🔧 **Güvenli Silme**: SwiftSyntax ile syntax-aware silme işlemleri
- 🧪 **Test Entegrasyonu**: Değişiklikler sonrası otomatik test çalıştırma
- 🌲 **Git Entegrasyonu**: Otomatik branch oluşturma, commit ve revert
- 📝 **Çoklu Rapor Formatları**: JSON, Text, Markdown, Xcode Diagnostics

## 📦 Kurulum

### Gereksinimler

- macOS 13.0+
- Xcode 15.0+
- Swift 6.0+

### Swift Package Manager ile

```bash
git clone https://github.com/yourusername/NSClear.git
cd NSClear
swift build -c release
```

Binary'yi system path'e kopyalayın:

```bash
cp .build/release/nsclear /usr/local/bin/
```

### Homebrew ile (Yakında)

```bash
brew install nsclear
```

## 🚀 Hızlı Başlangıç

### Xcode Projesi için

```bash
# 1. Önce projenizi build edin (index store oluşturmak için)
xcodebuild -workspace MyApp.xcworkspace -scheme MyApp build

# 2. NSClear'ı çalıştırın
nsclear scan --workspace MyApp.xcworkspace --scheme MyApp --interactive
```

### SwiftPM Projesi için

```bash
# 1. Index store ile build edin
swift build -Xswiftc -index-store-path -Xswiftc .build/index/store

# 2. NSClear'ı çalıştırın
nsclear scan --package-path . --index-store-path .build/index/store --interactive
```

## 📖 Kullanım

### Temel Komutlar

#### `scan` - Analiz Yap

```bash
# Sadece tarama (değişiklik yapmaz)
nsclear scan

# İnteraktif mod
nsclear scan --interactive

# JSON raporu oluştur
nsclear scan --format json --write-report report.json

# Xcode diagnostics formatında
nsclear scan --format xcode

# Markdown raporu
nsclear scan --format markdown --write-report report.md
```

#### `apply` - Değişiklikleri Uygula

```bash
# İnteraktif mod ile uygula (önerilen)
nsclear scan --interactive --apply

# Otomatik uygula (max risk 20)
nsclear apply --max-risk 20

# Belirli bir workspace için
nsclear apply --workspace MyApp.xcworkspace --scheme MyApp --max-risk 15
```

#### `report` - Rapor Oluştur

```bash
# JSON'dan text raporu
nsclear report report.json --format text

# Markdown raporu
nsclear report report.json --format markdown --output report.md
```

### Konfigürasyon

Projenizin root dizininde `.nsclear.yml` dosyası oluşturun:

```yaml
# Hariç tutulacak dosyalar
exclude:
  - "**/Tests/**"
  - "**/.build/**"

# Risk skorlama
riskScoring:
  publicAPIWeight: 90
  objcDynamicWeight: 95
  privateHelperWeight: 10

# Koruma kuralları
protections:
  protectObjC: true
  protectDynamic: true
  protectIB: true

# Otomatik seçim için maksimum risk
maxAutoSelectRisk: 20

# Test yapılandırması
testing:
  runTests: true
  swiftTestCommand: "swift test"

# Git yapılandırması
git:
  autoCommit: true
  branchPrefix: "nsclear"
```

Tam konfigürasyon örneği için [.nsclear.yml](.nsclear.yml) dosyasına bakın.

## 🎯 Nasıl Çalışır?

1. **Syntax Analizi**: SwiftSyntax ile tüm Swift dosyalarını parse eder ve declaration'ları toplar
2. **Index Store Analizi**: IndexStoreDB ile sembol referanslarını ve ilişkileri çıkarır
3. **Entry Point Belirleme**: `@main`, SwiftUI.App, public API gibi entry point'leri tanımlar
4. **Reachability Analizi**: Entry point'lerden başlayarak erişilebilir kodu belirler
5. **Risk Skorlaması**: Her kullanılmayan declaration için risk skoru hesaplar
6. **İnteraktif Gözden Geçirme**: Kullanıcı bulguları gözden geçirir ve seçer
7. **Güvenli Silme**: Seçilen declaration'ları SwiftSyntax ile siler
8. **Test & Commit**: Testleri çalıştırır ve başarılıysa commit eder

## 🛡️ Güvenlik Özellikleri

NSClear, kritik kodu korumak için çeşitli güvenlik mekanizmaları içerir:

### Otomatik Korunuyor

- `@objc` ve `dynamic` - Objective-C runtime erişimi
- `@IBAction`, `@IBOutlet` - Interface Builder bağlantıları
- `@NSManaged` - Core Data özellikleri
- `@inlinable`, `@usableFromInline` - ABI stabilitesi
- `@_cdecl` - C fonksiyon export'ları
- `@_spi` - System Programming Interface
- SwiftUI Previews - `_Previews` soneki olan structlar
- Public/Open API (varsayılan olarak)

### Güvenli İşlem Akışı

1. **Dry-run Varsayılan**: `--apply` flag'i olmadan hiçbir değişiklik yapılmaz
2. **Backup**: Değişiklikler öncesi otomatik backup oluşturulur
3. **Test Gate**: Testler başarısız olursa değişiklikler geri alınır
4. **Git Branch**: Değişiklikler yeni branch'te yapılır
5. **İnteraktif Onay**: Kullanıcı her değişikliği manuel kontrol edebilir

## 📊 Risk Skorlaması

Her bulgu 0-100 arası bir risk skoru alır:

| Risk Seviyesi | Skor | Açıklama |
|--------------|------|----------|
| 🟢 Düşük | 0-19 | Private helper'lar, güvenli silme |
| 🟡 Orta | 20-49 | Internal kod, test kodları |
| 🟠 Yüksek | 50-79 | Public API, protocol implementasyonları |
| 🔴 Çok Yüksek | 80-100 | ObjC/dynamic, kritik attributeler |

Risk skorunu etkileyen faktörler:

- Access level (private → open)
- Attribute'lar (@objc, @IBAction, vb.)
- Modifier'lar (dynamic)
- Protocol requirement/witness durumu
- Referans sayısı

## 🎨 İnteraktif TUI Komutları

```
[t <num>]    - Toggle selection (örn: 't 1' veya 't 1-5' veya 't all')
[v <num>]    - View details (örn: 'v 1')
[d <num>]    - View diff (örn: 'd 1')
[n]          - Next page
[p]          - Previous page
[a]          - Apply deletions
[q]          - Quit without applying
```

## 📝 Örnek Çıktılar

### Text Raporu

```
╔══════════════════════════════════════════════════════════════════════════════╗
║                        NSClear - Analiz Raporu                               ║
╚══════════════════════════════════════════════════════════════════════════════╝

📊 ÖZET
────────────────────────────────────────────────────────────────────────────────
Tarih: Oct 8, 2025 at 10:30 AM
Toplam Declaration: 542
Kullanılmayan: 47
Kullanım Oranı: 91.3%
Analiz Edilen Dosya: 23
Entry Point: 12

🎯 RİSK DAĞILIMI
────────────────────────────────────────────────────────────────────────────────
🟢 Low         : 32 adet (68.1%)
🟡 Medium      : 10 adet (21.3%)
🟠 High        : 4 adet (8.5%)
🔴 Very High   : 1 adet (2.1%)
```

### JSON Raporu

```json
{
  "findings": [
    {
      "id": "...",
      "declaration": {
        "kind": "function",
        "name": "unusedHelper",
        "filePath": "/path/to/file.swift",
        "line": 42,
        "riskScore": 15
      },
      "reason": "Entry point değil, hiçbir yerden referans edilmiyor"
    }
  ],
  "totalDeclarations": 542,
  "unusedCount": 47
}
```

## 🧪 Test

```bash
# Unit testleri çalıştır
swift test

# Verbose output ile
swift test --verbose
```

## 🤝 Katkıda Bulunma

Katkılarınızı bekliyoruz! Lütfen şu adımları izleyin:

1. Fork edin
2. Feature branch oluşturun (`git checkout -b feature/amazing-feature`)
3. Değişikliklerinizi commit edin (`git commit -m 'feat: add amazing feature'`)
4. Branch'inizi push edin (`git push origin feature/amazing-feature`)
5. Pull Request açın

### Commit Mesaj Formatı

[Conventional Commits](https://www.conventionalcommits.org/) kullanıyoruz:

- `feat:` - Yeni özellik
- `fix:` - Hata düzeltmesi
- `refactor:` - Kod iyileştirmesi
- `docs:` - Dokümantasyon
- `test:` - Test ekleme/düzeltme
- `chore:` - Build, CI/CD vb.

## 🐛 Bilinen Sorunlar ve Sınırlamalar

1. **IndexStore Gereksinimi**: En iyi sonuçlar için index store gereklidir
2. **SwiftUI Property Wrappers**: Bazı durumlarda @State, @Binding vb. yanlış pozitif verebilir
3. **Objective-C Interop**: Objective-C'den kullanılan Swift kodu tam tespit edilemeyebilir
4. **Reflection/Mirrors**: Runtime reflection ile erişilen kod tespit edilemez
5. **String-based Selectors**: Selector stringleri statik analiz ile tam tespit edilemez

## 🗺️ Yol Haritası

- [ ] GitHub Action entegrasyonu
- [ ] Xcode Source Editor Extension
- [ ] CI/CD pipeline entegrasyonu (Jenkins, CircleCI)
- [ ] Web-based rapor görüntüleyici
- [ ] Incremental analysis (sadece değişen dosyalar)
- [ ] Multi-module Swift Package desteği
- [ ] Performance optimizasyonları
- [ ] ML-based false positive detection

## 📄 Lisans

Bu proje MIT lisansı altında lisanslanmıştır. Detaylar için [LICENSE](LICENSE) dosyasına bakın.

## 🙏 Teşekkürler

- [swift-syntax](https://github.com/apple/swift-syntax) - Swift parser ve syntax tree
- [IndexStoreDB](https://github.com/apple/indexstore-db) - Index store erişimi
- [swift-argument-parser](https://github.com/apple/swift-argument-parser) - CLI argument parsing
- [Yams](https://github.com/jpsim/Yams) - YAML parsing

## 📧 İletişim

- Issues: [GitHub Issues](https://github.com/yourusername/NSClear/issues)
- Discussions: [GitHub Discussions](https://github.com/yourusername/NSClear/discussions)

---

**NSClear ile Swift kodunuz temiz ve düzenli! 🧹✨**

