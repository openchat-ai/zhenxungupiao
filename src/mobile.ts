import { Capacitor } from '@capacitor/core';
import { SplashScreen } from '@capacitor/splash-screen';
import { StatusBar, Style } from '@capacitor/status-bar';

/** 在原生壳（Android / iOS）里初始化状态栏与启动屏。 */
export async function initMobileShell() {
  if (!Capacitor.isNativePlatform()) return;

  document.documentElement.classList.add('native-app');

  try {
    await StatusBar.setStyle({ style: Style.Dark });
    await StatusBar.setBackgroundColor({ color: '#0b0e11' });
  } catch {
    // iOS 部分机型不支持 setBackgroundColor
  }

  try {
    await SplashScreen.hide();
  } catch {
    // ignore
  }
}

export const isNativeApp = () => Capacitor.isNativePlatform();
