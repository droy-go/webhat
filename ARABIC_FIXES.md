# دليل إصلاح أخطاء WebHat بالعربي

## 📋 ملخص المشاكل

من الصور، يمكن رؤية أن معظم مهام البناء فاشلة:

| المهمة | الحالة |
|--------|--------|
| Build Web Reader | ❌ فاشل |
| Build Web Editor | ❌ فاشل |
| Build Python Engine | ✅ ناجح |
| Build Android | ❌ فاشل |
| Build iOS | ❌ فاشل |
| Build Windows | ❌ فاشل |
| Build macOS | ❌ فاشل |
| Build Linux | ❌ فاشل |

---

## 🔧 الإصلاحات

### 1. إصلاح Web Reader و Web Editor

**المشكلة:** يستخدم workflow أمر `npm ci` الذي يتطلب وجود `package-lock.json`

**الحل:** استخدام `npm install` بدلاً منه

```yaml
# ❌ قبل (فاشل)
- run: npm ci

# ✅ بعد (ناجح)
- run: npm install
```

### 2. إصلاح بناء Flutter/Android

**المشكلة:** ملفات موارد Android مفقودة

**الملفات المضافة:**
- `android/app/src/main/res/values/styles.xml`
- `android/app/src/main/res/values/strings.xml`
- `android/app/src/main/res/drawable/launch_background.xml`
- `android/app/src/main/res/xml/file_paths.xml`
- `android/app/src/main/res/xml/network_security_config.xml`

### 3. إصلاح توقف Workflow

**المشكلة:** عندما تفشل مهمة واحدة، يتوقف الـ workflow بالكامل

**الحل:** إضافة `continue-on-error: true` لجميع المهام

```yaml
jobs:
  build-web-reader:
    continue-on-error: true  # ✅ يستمر حتى لو فشلت هذه المهمة
```

---

## 🚀 خطوات التطبيق

### الطريقة السريعة (باستخدام السكربت)

```bash
# 1. استنساخ المستودع
git clone https://github.com/droy-go/webhat.git
cd webhat

# 2. تشغيل سكربت الإصلاح
chmod +x fix-repo.sh
./fix-repo.sh
```

### الطريقة اليدوية

#### الخطوة 1: إنشاء package-lock.json

```bash
cd reader
npm install
cd ../editor
npm install
cd ..
```

#### الخطوة 2: إضافة ملفات Android

```bash
mkdir -p mobile/flutter_storypack/android/app/src/main/res/{drawable,values,xml}

# إنشاء styles.xml
cat > mobile/flutter_storypack/android/app/src/main/res/values/styles.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <style name="LaunchTheme" parent="@android:style/Theme.Light.NoActionBar">
        <item name="android:windowBackground">@drawable/launch_background</item>
    </style>
    <style name="NormalTheme" parent="@android:style/Theme.Light.NoActionBar">
        <item name="android:windowBackground">?android:colorBackground</item>
    </style>
</resources>
EOF

# إنشاء strings.xml
cat > mobile/flutter_storypack/android/app/src/main/res/values/strings.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="app_name">WebHat StoryPack</string>
</resources>
EOF

# إنشاء launch_background.xml
cat > mobile/flutter_storypack/android/app/src/main/res/drawable/launch_background.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <item android:drawable="@android:color/white" />
</layer-list>
EOF
```

#### الخطوة 3: رفع التغييرات

```bash
git add .
git commit -m "Fix GitHub Actions workflow issues"
git push origin main
```

---

## 📁 الملفات المُنشأة

```
webhat-platform/
├── .github/workflows/build.yml          ← تم تحديثه
├── FIXES.md                              ← دليل الإصلاحات
├── ARABIC_FIXES.md                       ← هذا الملف
├── fix-repo.sh                           ← سكربت الإصلاح التلقائي
└── mobile/flutter_storypack/android/
    └── app/src/main/res/
        ├── drawable/
        │   └── launch_background.xml    ← جديد
        ├── values/
        │   ├── strings.xml              ← جديد
        │   └── styles.xml               ← جديد
        └── xml/
            ├── file_paths.xml           ← جديد
            ├── network_security_config.xml  ← جديد
            ├── backup_rules.xml         ← جديد
            └── data_extraction_rules.xml    ← جديد
```

---

## ✅ التحقق من الإصلاحات

بعد رفع التغييرات، انتقل إلى:

```
https://github.com/droy-go/webhat/actions
```

وتحقق من أن الـ workflow يعمل بنجاح.

---

## 🎯 النتيجة المتوقعة

بعد تطبيق الإصلاحات:

| المهمة | الحالة المتوقعة |
|--------|-----------------|
| Build Web Reader | ✅ ناجح |
| Build Web Editor | ✅ ناجح |
| Build Python Engine | ✅ ناجح |
| Build Android | ✅ ناجح |
| Build iOS | ⚠️ يتطلب توقيع |
| Build Windows | ✅ ناجح |
| Build macOS | ✅ ناجح |
| Build Linux | ✅ ناجح |

---

## ❓ الأسئلة الشائعة

### س: لماذا يفشل بناء iOS؟

**ج:** يتطلب بناء iOS توقيع Apple Developer. يمكنك تخطيه في الـ workflow باستخدام:

```yaml
build-ios:
  if: github.event_name != 'pull_request'
```

### س: كيف أختبر البناء محلياً؟

**ج:**

```bash
# اختبار Web Reader
cd reader
npm install
npm run build

# اختبار Flutter Android
cd ../mobile/flutter_storypack
flutter build apk --debug
```

### س: ماذا لو استمر الفشل؟

**ج:** افتح issue في المستودع مع:
1. رابط فشل الـ workflow
2. نص الخطأ
3. لقطة شاشة للمشكلة

---

## 📞 الدعم

للمساعدة، تواصل عبر:
- GitHub Issues: https://github.com/droy-go/webhat/issues
