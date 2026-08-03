// 无障碍服务 - 用于模拟点击
// AccessExtension.ets

import accessAbility from '@ohos.accessibility';

@ExtensionAbility({ name: 'TicketClickExtension', type: 'accessibility' })
export default class TicketClickExtension extends AccessAbility {
  private deviceId: number = -1;
  
  onAbilityCreate(): void {
    console.info('无障碍服务创建');
  }
  
  onAbilityDestroy(): void {
    console.info('无障碍服务销毁');
  }
  
  // 获取设备 ID
  getDeviceId(): number {
    if (this.deviceId === -1) {
      this.deviceId = accessAbility.getDeviceId();
    }
    return this.deviceId;
  }
  
  // 模拟点击
  tap(x: number, y: number): boolean {
    try {
      // 使用无障碍 API 模拟点击
      const event = new accessAbility.AccessibilityEvent();
      event.type = accessAbility.EventType.TYPE_VIEW_CLICKED;
      event.x = x;
      event.y = y;
      event.deviceId = this.getDeviceId();
      
      accessAbility.sendEvent(event);
      console.info(`模拟点击成功 (${x}, ${y})`);
      return true;
    } catch (e) {
      console.error('点击失败:', e);
      return false;
    }
  }
  
  // 多次点击
  rapidTap(x: number, y: number, count: number, interval: number): Promise<void> {
    return new Promise((resolve) => {
      let clicked = 0;
      
      const timer = setInterval(() => {
        if (clicked >= count) {
          clearInterval(timer);
          resolve();
          return;
        }
        
        this.tap(x, y);
        clicked++;
      }, interval);
    });
  }
}
