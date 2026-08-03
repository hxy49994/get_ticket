// 简化版无障碍服务 - 使用系统输入事件
// AccessExtension_Simple.ets

import UIAbility from '@ohos.app.ability.UIAbility';
import hilog from '@ohos.hilog';
import window from '@ohos.window';

export default class AccessExtension extends UIAbility {
  private windowController: window.WindowController = null;
  
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(0x0000, 'ClickService', 'Service created');
  }
  
  onDestroy(): void {
    hilog.info(0x0000, 'ClickService', 'Service destroyed');
  }
  
  // 发送点击事件到指定坐标
  sendTapEvent(x: number, y: number): boolean {
    try {
      // 使用系统输入事件
      const inputManager = inputManager.getInputManager();
      const event = inputManager.createMotionEvent();
      event.x = x;
      event.y = y;
      event.action = inputManager.ACTION_DOWN;
      
      inputManager.injectInputEvent(event, inputManager.INJECT_MODE_ASYNC);
      hilog.info(0x0000, 'ClickService', `Tap sent: (${x}, ${y})`);
      return true;
    } catch (e) {
      hilog.error(0x0000, 'ClickService', `Tap failed: ${JSON.stringify(e)}`);
      return false;
    }
  }
  
  // 快速连续点击
  rapidTap(x: number, y: number, count: number, interval: number): void {
    let i = 0;
    const timer = setInterval(() => {
      if (i >= count) {
        clearInterval(timer);
        return;
      }
      this.sendTapEvent(x, y);
      i++;
    }, interval);
  }
}
