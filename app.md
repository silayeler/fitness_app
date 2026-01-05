# Posturify - Uygulama Teknik Analizi ve Çalışma Mantığı

Bu belge, **Posturify** uygulamasının nasıl çalıştığını, arka planda hangi teknolojileri kullandığını ve oyunlaştırma (XP) sisteminin mantığını detaylıca açıklar.

---

## 1. Temel Teknoloji ve Mimari (Nasıl Çalışıyor?)
Bu uygulama, **"Edge Computing" (Cihaz İçi Hesaplama)** prensibiyle çalışır. Yani hiçbir görüntü sunucuya gitmez, her şey senin telefonunda anlık olarak hesaplanır.

### Akış Şeması
1.  **Kamera**: 30 FPS (Saniye başına kare) hızında görüntü alır.
2.  **Yapay Zeka (Google ML Kit)**: Gelen her kareyi tarar ve insan vücudundaki **33 temel eklem noktasını** (omuz, dirsek, kalça, diz, bilek vb.) tespit eder.
3.  **Matematiksel Analiz (Geometri)**: Tespit edilen noktalar arasındaki açıları hesaplar (Örn: Kalça-Diz-Ayak Bileği açısı).
4.  **Egzersiz Mantığı (Logic Katmanı)**: Hesaplanan açıları, tanımlı kurallarla kıyaslar (Örn: Squat için diz açısı < 100 olmalı).
5.  **Geri Bildirim**: Sonuca göre ekrana çizim yapar (Yeşil/Kırmızı iskelet) ve sesli komut verir.

---

## 2. Egzersiz Mantığı (State Machine)
Her egzersiz, bir "Durum Makinesi" (State Machine) mantığıyla çalışır. Bu, hatalı sayımları önlemek için hareketin evrelerini takip eder.

### Örnek: Mekik (Sit-up)
Sistemin bir tekrarı sayması için şu sırayı takip etmesi **ZORUNLUDUR**:
1.  **Durum 1: Nötr (Yatış)**
    *   Vücut açısı **> 125 derece** olmalı. (Henüz başlamadın)
2.  **Durum 2: Aktif (Sıkıştırma)**
    *   Vücut öne doğru kapanır ve açı **< 115 dereceye** düşer.
    *   Bu noktada sistem *"Tetiklendi"* (Triggered) durumuna geçer ve ekranda "Harika!" yazar.
3.  **Durum 3: Bitiş (Tekrar)**
    *   Tekrar **> 125 dereceye** (Yatış) dönüldüğünde sayaç **+1 artar**.
    *   Sistem sıfırlanır ve yeni tekrarı bekler.

*Bu sistem sayesinde yarım yapılan veya titreyerek yapılan hareketler sayılmaz.*

---

## 3. Puanlama ve Form Analizi (Yeşil Puan)
Ekranda gördüğün 100 üzerinden verilen puan (Form Score), senin hareket kaliteni gösterir.

*   **Hesaplama**: Her egzersizin ideal bir "Hedef Açısı" vardır.
    *   *Squat Hedefi*: 90 derece (Tam çöküş).
    *   *Senin Açın*: 95 derece ise puanın yüksek olur (~90/100).
    *   *Senin Açın*: 130 derece ise (sadece eğildin) puanın 0 olur.
*   **Ortalama**: Antrenman boyunca aldığın tüm anlık puanların ortalaması, antrenman sonundaki "Form Puanı"nı oluşturur.

---

## 4. Ödül ve XP Sistemi (Gamification)
Kullanıcıyı motive eden XP (Tecrübe Puanı) sistemi, hem süreyi hem de kaliteyi ödüllendirecek şekilde tasarlanmıştır.

### XP Formülü
```dart
Toplam XP = (Baz Puan) + (Süre Bonusu) + (Kalite Bonusu)
```
1.  **Baz Puan (20 XP)**: Antrenmanı bitirdiğin için verilen sabit ödül.
2.  **Süre Bonusu (10 XP / dk)**: Çalıştığın her dakika için 10 XP. (5 dk = 50 XP).
3.  **Kalite Bonusu (Form Puanı / 2)**: Form puanının yarısı kadar ekstra XP.
    *   Formun 100 (Mükemmel) ise -> **+50 XP**
    *   Formun 40 (Kötü) ise -> **+20 XP**

*Özetle: Sadece çok çalışmak yetmez, hareketi doğru yapmak daha fazla puan kazandırır.*

---

## 5. Veri Saklama (Back-end Yok)
Uygulama "Serverless" (Sunucusuz) yapıdadır.
*   **Veritabanı**: `Hive` (Hızlı, yerel NoSQL veritabanı) kullanılır.
*   **Konum**: Tüm veriler (İsim, Kilo, Geçmiş, XP, Seviye) telefonunun hafızasında şifreli olarak saklanır.
*   **Gizlilik**: İnternet bağlantısı olmasa bile uygulama tam performansla çalışır.

---

## Özet Tablo

| Özellik | Kullanılan Teknoloji / Mantık |
| :--- | :--- |
| **Görüntü İşleme** | Google ML Kit (Pose Detection) |
| **İskelet Çizimi** | Flutter CustomPainter |
| **Hareket Sayma** | Geometrik Açı Analizi + State Machine |
| **Veri Kaydı** | Hive (Yerel Depolama) |
| **Sesli Komut** | Text-to-Speech (TTS) |
| **Arayüz (UI)** | Flutter Material Design (Glassmorphism) |

Bu yapı, uygulamanın hem **çok hızlı** çalışmasını hem de **%100 güvenli** olmasını sağlar.
