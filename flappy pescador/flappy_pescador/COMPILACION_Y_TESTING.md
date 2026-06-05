# Compilación y Testing - Flappy Pescador

## 🚀 Configuración Rápida

### Requisitos
- Godot 4.2+ (GL Compatibility renderer)
- Para Android: Android SDK, NDK, JDK
- Para iOS: Xcode (en Mac)

## 🧪 Testing en Editor

### Antes de exportar:
1. Abre el proyecto en Godot Editor
2. Presiona **F5** o el botón **Play**
3. Verifica:
   - ✅ Juego se abre en modo vertical
   - ✅ Puntuación visible y legible
   - ✅ Botón de pausa funcional
   - ✅ Salto responde al click del ratón
   - ✅ Paneles de inicio/game over bien posicionados

### Testing avanzado en editor:
```gdscript
# En la consola de debug (Output):
# Verifica que no haya errores de orientación o viewport
```

## 📦 Compilación para Android

### Opción 1: Desde Godot Editor (Recomendado)

1. **Configurar exportación:**
   - Project → Export → Agregar preset Android
   - Nombre: "Android - Vertical"
   
2. **Configurar opciones Android:**
   - Minimum SDK: 21 (Android 5.0)
   - Target SDK: 34 (Android 14)
   - Orientation: Portrait
   
3. **Compilar:**
   ```bash
   # En Godot Editor
   Project → Export → Export as APK
   Selecciona ubicación de salida
   ```

### Opción 2: Desde línea de comandos

```bash
# Compilar APK
godot --export "Android - Vertical" build/flappy_pescador.apk

# Compilar AAB (Google Play)
godot --export "Android - Vertical (AAB)" build/flappy_pescador.aab
```

## 🍎 Compilación para iOS

### Desde Mac:

1. **Preparar proyecto:**
   - Godot 4.2+ (versión para Mac)
   - Xcode instalado

2. **Exportar:**
   ```bash
   # Exportar proyecto iOS
   godot --export "iOS" build/flappy_pescador.ipa
   ```

3. **Compilar en Xcode:**
   ```bash
   cd build/ios
   xcodebuild -project FlappyPescador.xcodeproj -scheme Release build
   ```

## 🧬 Testing en Dispositivo Real

### Android:

1. **Habilita modo desarrollador:**
   - Configuración → Acerca del teléfono
   - Presiona "Número de compilación" 7 veces
   - Configuración → Opciones de desarrollador → USB Debugging

2. **Conecta y prueba:**
   ```bash
   adb install build/flappy_pescador.apk
   adb logcat # Ver logs
   ```

### iOS:

1. **Firma la aplicación:**
   - Abre en Xcode
   - Selecciona Development Team
   - Build & Run

## ✅ Checklist de Testing en Dispositivo

Antes de publicar, verifica:

- [ ] Juego se inicia correctamente
- [ ] Pantalla está en modo vertical
- [ ] Puntuación es legible y visible
- [ ] Salto responde al primer toque
- [ ] Botón de pausa funciona
- [ ] Game over muestra puntuación correcta
- [ ] Mejor puntuación se guarda y persiste
- [ ] Panel de pausa se puede resumir
- [ ] Sin errores en logcat/Console
- [ ] Audio funciona (música de fondo + SFX)
- [ ] Funciona con y sin notch
- [ ] Performance estable (60 FPS)

## 🐛 Solución de Problemas

### Problema: Pantalla en horizontal
**Solución:**
```
Project Settings → Display → Window → Handheld Orientation → Portrait
Recompila y exporta
```

### Problema: Controles lentos
**Solución:**
- Cierra otras aplicaciones
- Verifica que el dispositivo no esté sobrecargado
- Prueba en otro dispositivo

### Problema: Puntuación no se guarda
**Solución:**
- Android: Verifica permisos de almacenamiento
- iOS: Verifica permisos de Documents

### Problema: Botón de pausa no responde
**Solución:**
- Verifica que no haya overlay de otras apps
- Reconstruye desde Godot

## 📝 Notas de Debugging

```gdscript
# Agregar esta línea en _ready() para debug:
print("Screen size: ", get_viewport().get_visible_rect().size)
print("Mobile: ", OS.get_name())
print("DPI: ", DisplayServer.screen_get_dpi())
```

## 🎯 Optimizaciones Finales

### Antes de publicar:
1. Configura ícono de aplicación (512x512 PNG)
2. Configura nombre y descripción
3. Establece versión (1.0.0)
4. Genera screenshot promocionales

### Tamaño final estimado:
- APK (Android): ~20-30 MB
- IPA (iOS): ~25-35 MB
- Muy ligero, sin dependencias externas

## 📊 Performance Esperado

- **FPS**: 60 FPS constante (optimizado)
- **CPU**: Bajo uso (renderizado sencillo)
- **RAM**: 30-50 MB
- **Batería**: Muy eficiente

## 🔄 Actualizaciones Futuras

Para actualizaciones:
1. Cambia versión en project.godot
2. Recompila
3. Sube nueva versión a stores

---
**Versión**: 1.0  
**Última actualización**: 2026-06-04  
**Plataformas**: Android 5.0+, iOS 11.0+
