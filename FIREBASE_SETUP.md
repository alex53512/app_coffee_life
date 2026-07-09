# Configuración de Firebase Cloud Messaging (FCM)

## En Firebase Console

1. Ve a https://console.firebase.google.com/
2. Crea un proyecto nuevo o usa uno existente
3. Agrega una app Android:
   - Package name: `com.example.app_coffee_life`
   - Descarga `google-services.json`
   - Colócalo en `android/app/google-services.json`
4. Agrega una app iOS (si aplica):
   - Bundle ID: `com.example.appCoffeeLife`
   - Descarga `GoogleService-Info.plist`
   - Colócalo en `ios/Runner/GoogleService-Info.plist`

## En el backend

El backend debe:

1. Usar Firebase Admin SDK para enviar notificaciones
2. Exponer un endpoint `POST /usuarios/fcm-token` que reciba `{"token": "..."}` y guarde el token del usuario
3. Enviar notificaciones push cuando:
   - Se cree un monitoreo con nivel Alto/Crítico
   - Se reciba una nueva recomendación
   - Se programe un tratamiento

### Ejemplo Node.js (backend)

```javascript
const admin = require('firebase-admin');
admin.initializeApp({ credential: admin.credential.applicationDefault() });

// Enviar notificación
await admin.messaging().send({
  token: fcmToken,
  notification: { title: 'Roya detectada', body: 'Nivel alto en Lote 3' },
  data: { idMonitoreo: '123', tipo: 'alerta' },
});
```

## Compilar

```bash
flutter clean
flutter pub get
flutter run
```
