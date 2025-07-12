# myapp

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.


$ flutter build apk --release --split-per-abi --target lib/src/main.dart

$ flutter run -t lib/src/main.dart

## 🔧 Configuración de Firebase para iOS

Esta app usa Firebase para autenticación, base de datos, etc.  
Para compilar en iOS, necesitás agregar manualmente el archivo de configuración de Firebase.

### 📄 Paso 1: Obtener el archivo `GoogleService-Info.plist`
1. Tienes que tener el archivo `GoogleService-Info.plist`.

### 📁 Paso 2: Colocar el archivo en el proyecto
Copiá el archivo en la siguiente ruta dentro del repo:
ios/
└── Runner/
    └── GoogleService-Info.plist  ← Aquí va tu PLIST

> ⚠️ **Importante**: Este archivo está ignorado en `.gitignore`, así que no se incluye en el repositorio.


para android

android/
└── app/
    └── google-services.json  ← Aquí va tu JSON
