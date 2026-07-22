import { CapacitorConfig } from "@capacitor/cli";

const config: CapacitorConfig = {
  appId: "za.co.schoolnet.app",
  appName: "SchoolNet",
  webDir: "../frontend/out",
  bundledWebRuntime: false,
  server: {
    url: process.env.NEXT_PUBLIC_APP_URL || "http://localhost:3000",
    cleartext: process.env.NODE_ENV === "development",
  },
  android: {
    buildOptions: {
      keystorePath: "android/app/schoolnet.keystore",
      keystoreAlias: "schoolnet",
    },
  },
  ios: {
    scheme: "SchoolNet",
    contentInset: "always",
  },
  plugins: {
    SplashScreen: {
      launchShowDuration: 2000,
      backgroundColor: "#0a0a0f",
      androidSplashResourceName: "splash",
      showSpinner: false,
    },
    StatusBar: {
      style: "DARK",
      backgroundColor: "#0a0a0f",
    },
    PushNotifications: {
      presentationOptions: ["badge", "sound", "alert"],
    },
  },
};

export default config;
