# Deploy AirPak Express to GitHub + Vercel + Expo Web

## 1. Push to GitHub

```bash
cd /workspace/shipnow_app
# Add all files
git add -A
git commit -m "AirPak Express v11 — full auth, AirPak rebrand, real dark map"
# Create a new empty repo at https://github.com/new (e.g. airpak-express-app)
# Then add the remote and push:
git remote add origin https://github.com/<your-user>/airpak-express-app.git
git branch -M main
git push -u origin main
```

If using 2FA, use a personal access token:
```bash
git remote set-url origin https://<TOKEN>@github.com/<your-user>/airpak-express-app.git
git push -u origin main
```

## 2. Deploy to Vercel

The repo already includes a `vercel.json`. Three options:

### Option A — Vercel dashboard
1. Visit https://vercel.com/new
2. Import the `airpak-express-app` repo
3. Framework preset: **Other**
4. Output directory: `build/web` (after running `flutter build web --release`)
5. Click **Deploy**

### Option B — Vercel CLI
```bash
npm i -g vercel
cd /workspace/shipnow_app
vercel login
vercel --prod
```

### Option C — One-shot upload of prebuilt static site
The `shipnow_web_build.zip` archive contains the prebuilt `build/web/`.
```bash
unzip shipnow_web_build.zip -d airpak-web
cd airpak-web
vercel --prod
```

## 3. Expo Web wrapper

The Flutter web build can be wrapped inside an Expo Web app for unified
mobile/web distribution. From the Flutter project root:

```bash
# Install Expo
npm i -g expo-cli

# Create a new wrapper project
npx create-expo-app airpak-expo --template blank
cd airpak-expo

# Add a WebView that loads the deployed Flutter web build
npx expo install react-native-webview

# Replace App.js with:
cat > App.js << 'EOF'
import { WebView } from 'react-native-webview';
import { View, StyleSheet } from 'react-native';
export default function App() {
  return (
    <View style={styles.container}>
      <WebView
        source={{ uri: 'https://your-deployed-airpak-site.com' }}
        style={{ flex: 1 }}
        originWhitelist={['*']}
      />
    </View>
  );
}
const styles = StyleSheet.create({ container: { flex: 1 } });
EOF

npx expo publish --web       # deploys to Expo's CDN
```

## Environment

After deployment, set these in the Vercel / Expo dashboard:

| Key | Value | Required |
|---|---|---|
| `API_BASE_URL` | `https://your-backend.com` | Yes |
| `LIVE_BRIDGE_URL` | `wss://your-backend.com/ws` | Yes |
| `STRIPE_PUBLISHABLE_KEY` | `pk_live_...` | Optional |
| `SUPABASE_URL` | `https://xxx.supabase.co` | Optional |
| `SUPABASE_ANON_KEY` | `eyJ...` | Optional |
| `MAPTILER_KEY` | `...` | Optional |

Without these keys the app runs in **mock mode** with realistic fake data.
