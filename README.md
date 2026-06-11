# AirPak Express — Global Logistics Platform

A complete 2050-style shipping & logistics customer app for **AirPak Express**, built with **Flutter 3.27** for web, iOS, and Android.

AirPak is the **routing platform** — customers see AirPak as their single point of contact while we ship through DHL, FedEx, UPS, USPS, Royal Mail, Aramex, J&T, SF Express, EMS, DPD, Australia Post, Canada Post, Yodel, and Glovo (and many more).

## Quick start

```bash
flutter pub get
flutter run -d chrome               # web
flutter run -d <ios-device>          # iOS
flutter run -d <android-device>      # Android
```

The app boots in **mock mode** by default — no API keys required. Demo credentials are prefilled on the login screen.

## Backend (Node.js)

```bash
cd shipnow_backend
npm install
node src/server.js                   # listens on http://localhost:3001
```

## Highlights

- 2050 design system with full dark mode
- Real-time WebSocket live bridge (chat, presence, typing)
- iOS 17 Pro Max Settings layout
- iMessage-style chat with Apple Intelligence smart replies
- Airpak Coin brand settlement token (15 fiat currencies)
- 14+ worldwide carriers with bundled brand SVGs
- Full-screen iOS-Maps-style live tracking (synthetic dark cartography)
- Multi-step onboarding: animated splash → welcome → register → OTP → Face ID → portal

See `DESIGN.md` for the design system cheatsheet.
