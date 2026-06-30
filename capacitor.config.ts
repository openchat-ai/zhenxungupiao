import type { CapacitorConfig } from '@capacitor/cli';

const config: CapacitorConfig = {
  appId: 'com.zhenxun.stock',
  appName: '震巽股票',
  webDir: 'dist',
  server: {
    androidScheme: 'https',
  },
  android: {
    backgroundColor: '#0b0e11',
  },
  ios: {
    backgroundColor: '#0b0e11',
    contentInset: 'automatic',
  },
  plugins: {
    SplashScreen: {
      launchAutoHide: true,
      backgroundColor: '#0b0e11',
      showSpinner: false,
    },
    StatusBar: {
      style: 'DARK',
      backgroundColor: '#0b0e11',
    },
  },
};

export default config;
