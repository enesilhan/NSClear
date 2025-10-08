# NSClear Kullanım Kılavuzu - Xcode Projeleri için 🚀

## 🎯 Hızlı Başlangıç

### Adım 1: NSClear'ı Hazırlayın

```bash
# NSClear dizinine gidin
cd /Users/enesilhan/Development/NSClear

# Release build yapın
swift build -c release

# Binary hazır: .build/release/nsclear
```

### Adım 2: Xcode Projenizi Hazırlayın

#### 2a. Proje Bilgilerini Toplayın

```bash
# Projenizin dizinine gidin
cd /path/to/YourProject

# Workspace varsa listeleyin
ls *.xcworkspace

# Scheme'leri görün
xcodebuild -list -workspace YourApp.xcworkspace
```

#### 2b. Index Store Oluşturun (ZORUNLU!)

NSClear, kodunuzu analiz etmek için index store'a ihtiyaç duyar:

```bash
# Workspace için:
xcodebuild -workspace YourApp.xcworkspace \
           -scheme YourScheme \
           clean build

# Project için:
xcodebuild -project YourApp.xcodeproj \
           -scheme YourScheme \
           clean build
```

**Index Store Konumu:**
- Genelde: `~/Library/Developer/Xcode/DerivedData/YourApp-xxxxx/Index/DataStore`
- NSClear otomatik algılar

### Adım 3: NSClear'ı Çalıştırın

#### Yöntem 1: Direkt Binary ile (Test için en kolay)

```bash
# Proje dizininizde:
cd /path/to/YourProject

# NSClear'ı çalıştırın
/Users/enesilhan/Development/NSClear/.build/release/nsclear scan \
  --workspace YourApp.xcworkspace \
  --scheme YourScheme \
  --interactive
```

#### Yöntem 2: Alias Oluşturun (Pratik)

```bash
# ~/.zshrc veya ~/.bash_profile dosyanıza ekleyin:
alias nsclear="/Users/enesilhan/Development/NSClear/.build/release/nsclear"

# Sonra:
source ~/.zshrc  # veya source ~/.bash_profile

# Artık direkt kullanabilirsiniz:
nsclear scan --workspace YourApp.xcworkspace --scheme YourScheme --interactive
```

#### Yöntem 3: Sistem'e Kurun (Kalıcı)

```bash
# /usr/local/bin oluşturun (yoksa)
sudo mkdir -p /usr/local/bin

# NSClear'ı kopyalayın
sudo cp /Users/enesilhan/Development/NSClear/.build/release/nsclear /usr/local/bin/

# Her yerden kullanın:
nsclear scan --workspace YourApp.xcworkspace --scheme YourScheme --interactive
```

---

## 🎨 Kullanım Senaryoları

### Senaryo 1: İlk Tarama (Sadece Rapor)

```bash
# Proje dizininde:
nsclear scan \
  --workspace MyApp.xcworkspace \
  --scheme MyApp \
  --format text
```

**Çıktı:** Terminal'de renkli rapor gösterir.

### Senaryo 2: JSON Raporu Oluştur

```bash
nsclear scan \
  --workspace MyApp.xcworkspace \
  --scheme MyApp \
  --format json \
  --write-report unused-code-report.json
```

**Çıktı:** `unused-code-report.json` dosyası oluşturulur.

### Senaryo 3: İnteraktif Mod (Önerilen)

```bash
nsclear scan \
  --workspace MyApp.xcworkspace \
  --scheme MyApp \
  --interactive
```

**Ne Yapar:**
1. Kodu analiz eder
2. Bulguları interaktif TUI'de gösterir
3. Her bulguyu gözden geçirebilirsiniz
4. Seçerek silebilirsiniz
5. Test çalıştırır
6. Git commit yapar

### Senaryo 4: Düşük Riskli Olanları Otomatik Temizle

```bash
nsclear apply \
  --workspace MyApp.xcworkspace \
  --scheme MyApp \
  --max-risk 20
```

**Dikkat:** Bu direkt değişiklik yapar! İnteraktif modu tercih edin.

### Senaryo 5: Manuel Index Store Belirtme

Bazen index store otomatik bulunamayabilir:

```bash
# Index store yolunu bulun:
ls ~/Library/Developer/Xcode/DerivedData/*/Index/DataStore

# Örnek: ~/Library/Developer/Xcode/DerivedData/MyApp-abcde123/Index/DataStore

# NSClear'a belirtin:
nsclear scan \
  --workspace MyApp.xcworkspace \
  --scheme MyApp \
  --index-store-path ~/Library/Developer/Xcode/DerivedData/MyApp-abcde123/Index/DataStore \
  --interactive
```

---

## ⚙️ Konfigürasyon Dosyası (.nsclear.yml)

Proje kök dizininizde `.nsclear.yml` oluşturun:

```yaml
# Hariç tutulacak dosyalar
exclude:
  - "**/Tests/**"
  - "**/ThirdParty/**"
  - "**/.build/**"

# Risk skorlama
riskScoring:
  publicAPIWeight: 90
  objcDynamicWeight: 95
  privateHelperWeight: 10

# Korunacaklar
protections:
  protectObjC: true
  protectDynamic: true
  protectIB: true

# Otomatik seçim max risk
maxAutoSelectRisk: 20

# Test ayarları
testing:
  runTests: true
  xcodebuildCommand: "xcodebuild -workspace MyApp.xcworkspace -scheme MyApp test"

# Git ayarları
git:
  autoCommit: true
  branchPrefix: "nsclear"
```

Sonra basitçe:

```bash
nsclear scan --interactive
```

---

## 🐛 Sorun Giderme

### Problem 1: "Index store bulunamadı"

**Çözüm:**
```bash
# Projeyi tekrar build edin
xcodebuild -workspace YourApp.xcworkspace -scheme YourScheme clean build

# Index store yolunu manuel belirtin
nsclear scan --index-store-path ~/Library/Developer/Xcode/DerivedData/.../Index/DataStore
```

### Problem 2: "Swift compiler bulunamadı"

**Çözüm:**
```bash
# Xcode command line tools'u kur
xcode-select --install

# Swift versiyonunu kontrol et
swift --version
```

### Problem 3: Çok fazla false positive

**Çözüm:** `.nsclear.yml` dosyasında koruma kurallarını artırın:

```yaml
protections:
  protectObjC: true
  protectDynamic: true
  protectIB: true
  protectPreviews: true
  protectExtensions: true
```

### Problem 4: Testler başarısız oluyor

**Çözüm:**
```bash
# Test'siz mod
nsclear scan --interactive --config .nsclear.yml

# .nsclear.yml içinde:
testing:
  runTests: false
```

---

## 💡 İpuçları

### 1. İlk Kullanımda
- Küçük bir feature branch'te test edin
- Interactive mode kullanın
- Düşük risk (🟢) olanlarla başlayın

### 2. Güvenli Workflow
```bash
# 1. Yeni branch oluştur
git checkout -b cleanup/unused-code

# 2. NSClear'ı çalıştır
nsclear scan --interactive --apply

# 3. Değişiklikleri gözden geçir
git diff

# 4. Testleri çalıştır
xcodebuild test -workspace ... -scheme ...

# 5. Push et
git push origin cleanup/unused-code
```

### 3. Periyodik Temizlik
```bash
# Haftalık rapor
nsclear scan --format json --write-report weekly-$(date +%Y%m%d).json

# Aylık cleanup
nsclear scan --interactive --max-risk 30
```

### 4. CI/CD Entegrasyonu (Gelecek)
```yaml
# .github/workflows/nsclear.yml
- name: Check unused code
  run: nsclear scan --format xcode
```

---

## 🎯 Örnek Senaryo: Gerçek Bir Proje

Diyelim ki `~/Projects/MyAwesomeApp` projeniz var:

```bash
# 1. Proje dizinine git
cd ~/Projects/MyAwesomeApp

# 2. Build yap (index store oluştur)
xcodebuild -workspace MyAwesomeApp.xcworkspace \
           -scheme MyAwesomeApp \
           clean build

# 3. Config dosyası oluştur
cat > .nsclear.yml << EOF
exclude:
  - "**/Pods/**"
  - "**/Tests/**"

maxAutoSelectRisk: 15

testing:
  runTests: true
  xcodebuildCommand: "xcodebuild -workspace MyAwesomeApp.xcworkspace -scheme MyAwesomeApp test"
EOF

# 4. NSClear'ı çalıştır (alias kullanarak)
nsclear scan --interactive

# 5. TUI'de:
# - Findings'leri gözden geçir
# - Low risk (🟢) olanları seç (t all komutu)
# - Apply (a komutu)
# - Testler otomatik çalışır
# - Başarılıysa otomatik commit

# 6. Sonuç:
git log --oneline -1
# > chore: clear unused code (23 declarations)
```

---

## 📊 Beklenen Çıktı Örnekleri

### Tarama Sonucu
```
🔍 NSClear - Kullanılmayan Kod Analizi Başlıyor...

📁 Swift dosyaları taranıyor...
   ✓ 156 Swift dosyası bulundu
📝 Syntax analizi yapılıyor...
   ✓ 1,847 declaration bulundu
📊 Index store hazırlanıyor...
   ✓ Index store hazır
🎯 Entry point'ler belirleniyor...
   ✓ 23 entry point bulundu
🔗 Reachability analizi yapılıyor...
   ✓ 89 erişilemeyen declaration tespit edildi
🎯 Risk skorlaması yapılıyor...
   ✓ 89 bulgu risk skorlaması tamamlandı

✅ Analiz tamamlandı!

╔══════════════════════════════════════════════════════════════════╗
║                    ANALIZ ÖZET                                   ║
╚══════════════════════════════════════════════════════════════════╝

📊 Toplam Declaration: 1,847
🔴 Kullanılmayan: 89
🟢 Kullanım Oranı: 95.2%
📁 Dosya: 156
🎯 Entry Point: 23
```

### İnteraktif TUI
```
╔══════════════════════════════════════════════════════════════════╗
║                  NSClear - Unused Code Finder                    ║
╚══════════════════════════════════════════════════════════════════╝

📊 Toplam: 89 kullanılmayan declaration bulundu
✅ Seçili: 45 declaration

1. [✓] 🟢 Function: formatDate
   📁 .../Utils/DateHelper.swift:42
   💡 Entry point değil, hiçbir yerden referans edilmiyor
   🎯 Risk: 12/100 (Low)

2. [ ] 🟡 Class: LegacyParser
   📁 .../Legacy/Parser.swift:10
   💡 Entry point değil, 0 referans
   🎯 Risk: 35/100 (Medium)

[t <num>] Toggle | [v <num>] Details | [d <num>] Diff | [a] Apply | [q] Quit
Komut girin: 
```

---

## 🚀 Hızlı Komutlar Cheat Sheet

```bash
# Sadece tara
nsclear scan

# İnteraktif mod
nsclear scan --interactive

# JSON rapor
nsclear scan --format json --write-report report.json

# Düşük riski otomatik temizle
nsclear apply --max-risk 20

# Xcode diagnostics
nsclear scan --format xcode

# Yardım
nsclear --help
nsclear scan --help
```

---

**Başarılar! 🎉 Sorularınız varsa GitHub Discussions'da sorun.**

