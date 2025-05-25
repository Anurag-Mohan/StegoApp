# 🎭 INFIX: Steganography Application

<p align="center">
 <img src="https://media.giphy.com/media/LaVp0AyqR5bGsC5Cbm/giphy.gif" width="200" alt="Future"/>
  <br>
  <em>🕵️‍♂️ Hide in Plain Sight • 🔐 Secure by Design • 📱 Encryption Magic</em>
</p>

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)
![Java](https://img.shields.io/badge/java-%23ED8B00.svg?style=for-the-badge&logo=openjdk&logoColor=white)
![Android](https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white)


</div>

---

## 🎥 Demo



### 🚀 Application Walkthrough
Watch the complete demonstration of INFIX Steganography Application in action:

<div align="center">

[![INFIX Steganography Demo](https://img.shields.io/badge/▶️-Watch%20Demo-red?style=for-the-badge&logo=youtube)](path/to/your/screen-recording.mp4)

</div>

<details>
<summary>🎬 <strong>Demo Highlights</strong></summary>

- 🔐 PIN authentication setup and usage
- 📝 Text-in-image hiding and extraction process  
- 🖼️ Image-in-image steganography workflow
- 🎥 Video steganography demonstration
- 💬 P2P chat functionality
- ⚡ Real-time processing and results

</details>

---

## ✨ Features

<p align="center">
  <img src="https://media.giphy.com/media/3oKIPEqDGUULpEU0aQ/giphy.gif" width="250" alt="Features Animation"/>
</p>

### 🎯 Core Steganographic Capabilities

<table>
<tr>
<td width="50%">

#### 📝 Text-in-Image

Hide and extract text messages within images using LSB encoding

#### 🖼️ Image-in-Image  

Embed secret images within carrier images with lossless quality

</td>
<td width="50%">

#### 🎥 Image-in-Video

Conceal images within video files using non-keyframe embedding

#### ⚡ Multi-threaded Processing

Optimized performance with parallel processing

</td>
</tr>
</table>

---

### 🌟 Additional Features

<div align="center">

| Feature | Description |
|---------|-------------|
| 🔐 **PIN Authentication** | Secure access control |
| 📡 **Offline P2P Chat** | Local Wi-Fi communication |
| 📱 **Cross-Platform UI** | Flutter responsive interface |
| 🗂️ **Advanced File Management** | Efficient media handling |

</div>

---

## 🛠️ Technologies Used

<div align="center">

### 🎨 Frontend (Flutter)
```
🚀 Framework: Flutter for cross-platform development
📦 Key Packages: file_picker, image_picker, path_provider
🔐 Permissions: permission_handler
```

### ⚙️ Backend (Java)  
```
🧠 Core Engine: Java steganographic processing
🎥 Video APIs: MediaCodec & MediaMuxer
💾 Memory: ByteBuffer optimization
🔄 Threading: ExecutorService management
```

</div>

---


## 🔧 Installation


### 📋 Prerequisites

<div align="center">

| Requirement | Version | Status |
|-------------|---------|--------|
| Flutter SDK | Latest Stable | ✅ |
| Android Studio | Latest | ✅ |
| Java JDK | 8+ | ✅ |
| Device/Emulator | Android/iOS | ✅ |

</div>

### 🚀 Setup Instructions

```bash
# 1️⃣ Clone the Repository
git clone https://github.com/yourusername/infix-steganography.git
cd infix-steganography

# 2️⃣ Install Flutter Dependencies  
flutter pub get

# 3️⃣ Build and Run
flutter run
```

<details>
<summary>📋 <strong>Android Permissions Configuration</strong></summary>

Add to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.ACCESS_WIFI_STATE" />
<uses-permission android:name="android.permission.CHANGE_WIFI_STATE" />
```

</details>

---

## 📖 Usage Guide


### 🏁 Getting Started

<div align="center">

```mermaid
graph TD
    A[📱 Launch App] --> B[🔐 Set PIN]
    B --> C[🏠 Main Menu]
    C --> D{Choose Action}
    D --> E[📝 Hide Data]
    D --> F[🔍 Extract Data]
    D --> G[💬 P2P Chat]
```

</div>


---

## 🏗️ Architecture


<div align="center">

```mermaid
graph TB
    subgraph "📱 Flutter Layer"
        A[main.dart] --> B[home_screen.dart]
        B --> C[hide_screen.dart]
        B --> D[extract_screen.dart]
        C --> E[result_screen.dart]
        D --> E
    end
    
    subgraph "☕ Java Layer"
        F[MainActivity.java] --> G[SteganographyHelper.java]
    end
    
    subgraph "💾 File System"
        H[Image Files] --> I[Video Files]
        I --> J[Temp Storage]
    end
    
    B -.->|MethodChannel| F
    G --> H
```

</div>

---

## 🔒 Security Features



<div align="center">

| Feature | Benefit | Visual |
|---------|---------|--------|
| 🔐 **PIN Protection** | Prevents unauthorized access | ![PIN](https://img.shields.io/badge/Security-PIN-green) |
| 🏠 **Local Processing** | No internet required | ![Offline](https://img.shields.io/badge/Mode-Offline-blue) |
| 🔍 **LSB Encoding** | Virtually undetectable | ![Stealth](https://img.shields.io/badge/Stealth-LSB-purple) |
| ✅ **Data Integrity** | Multiple verification | ![Verified](https://img.shields.io/badge/Status-Verified-success) |

</div>

---

## ⚡ Performance Optimizations


<div align="center">

### 🚀 Speed Enhancements

```
🔄 Multi-threading    → Parallel CPU core utilization
🧠 Memory Management  → Efficient bitmap recycling  
📦 LZ4 Compression    → Fast, lightweight compression
💾 Smart Caching      → Optimal temporary storage
```

</div>

---

## 🐛 Troubleshooting


<details>
<summary>🚫 <strong>Permission Denied Errors</strong></summary>

- ✅ Grant all required permissions in device settings
- ✅ Verify Android manifest configuration
- ✅ Restart app after permission changes

</details>

<details>
<summary>💾 <strong>Large File Processing</strong></summary>

- 📊 Monitor device memory usage
- ⚡ Process files in smaller chunks
- 🔄 Clear cache regularly

</details>

<details>
<summary>❌ <strong>Extraction Failures</strong></summary>

- ✅ Verify file was created using this app
- 🔍 Check for file corruption
- 📁 Ensure proper file format

</details>

---

## 🚧 Future Enhancements


<div align="center">

| Enhancement | Priority | Status |
|-------------|----------|--------|
| 🎵 Audio File Support | High | 🔄 Planning |
| 🔐 Advanced Encryption | Medium | 🔄 Research |
| ☁️ Cloud Sync | Low | 💭 Concept |
| 📦 Batch Processing | Medium | 📋 Backlog |

</div>

---

## 📊 Technical Specifications

<div align="center">

| Feature | Specification | Visual |
|---------|---------------|--------|
| 📱 **Platforms** | Android, iOS | ![Platform](https://img.shields.io/badge/Platform-Cross--Platform-brightgreen) |
| 🎨 **Frontend** | Flutter/Dart | ![Frontend](https://img.shields.io/badge/Frontend-Flutter-blue) |
| ⚙️ **Backend** | Java | ![Backend](https://img.shields.io/badge/Backend-Java-orange) |
| 📦 **Compression** | LZ4, Deflater/Inflater | ![Compression](https://img.shields.io/badge/Compression-LZ4-purple) |
| 🔄 **Threading** | Multi-core parallel | ![Threading](https://img.shields.io/badge/Threading-Multi--core-green) |
| 🔐 **Security** | PIN auth, LSB encoding | ![Security](https://img.shields.io/badge/Security-PIN%2BLSB-darkgreen) |

</div>

---

<div align="center">

<img src="https://media.giphy.com/media/l0HlN5Y28D9MzzcRy/giphy.gif" width="100" alt="Thank You"/>

**Built with ❤️ using Flutter and Java**

*🕵️‍♂️ Hide in Plain Sight • 🔐 Secure by Design • 📱 Cross-Platform Magic*

---

<img src="https://media.giphy.com/media/26tn33aiTi1jkl6H6/giphy.gif" width="50"/> **Thank you for exploring INFIX!** <img src="https://media.giphy.com/media/26tn33aiTi1jkl6H6/giphy.gif" width="50"/>

</div>
