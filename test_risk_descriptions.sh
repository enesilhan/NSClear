#!/bin/bash

# Test script to show detailed risk descriptions

echo "Testing NSClear Risk Descriptions"
echo "=================================="
echo ""

# Run NSClear and capture first finding details
cd /Users/enesilhan/Development/AkakceCase

# Create a mock finding detail output
echo "📋 Declaration Detayları"
echo "══════════════════════════════════════════════════════════════════════"
echo ""
echo "🏷️  İsim: ViewController"
echo "📦 Tür: Class"
echo "📁 Dosya: AkakceCase/ViewController.swift"
echo "📍 Konum: Satır 10, Sütun 1"
echo "🔐 Erişim: internal"
echo "🏷️  Attributes: -"
echo "🔧 Modifiers: -"
echo ""
echo "💡 Sebep: 🔍 Entry point değil (fast mode - basit analiz) | ❌ Hiçbir yerden referans edilmiyor"
echo ""
echo "🎯 Risk Skoru: 20/100"
echo "⚠️  Risk Seviyesi: Medium"
echo ""
echo "📌 Referanslar: 0 adet"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📋 ÖNERİLEN AKSİYON:"
echo ""
echo "⚠️  KONTROL GEREKLİ: Silmeden önce kontrol edin"
echo ""
echo "Önerilen adımlar:"
echo "1. Kod içeriğini inceleyin"
echo "2. Gerçekten kullanılmadığından emin olun"
echo "3. Internal erişim - modül içi kullanım olabilir"
echo "4. Kodu yorum satırına alın (silmeyin)"
echo "5. Build + test çalıştırın"
echo "6. Birkaç gün sonra sorun yoksa silin"
echo ""
echo "Bu declaration orta risk seviyesinde. Manuel doğrulama önerilir."
echo ""
echo "══════════════════════════════════════════════════════════════════════"

