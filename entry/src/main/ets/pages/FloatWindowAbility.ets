// FloatWindowAbility.ets - 悬浮窗页面

@Entry
@Component
struct FloatWindowAbility {
  @State countdownText: string = '--:--:--';
  @State isRunning: boolean = false;
  private timer: number = -1;
  
  aboutToAppear(): void {
    this.startFloatingCountdown();
  }
  
  aboutToDisappear(): void {
    this.stopFloatingCountdown();
  }
  
  // 启动悬浮倒计时
  startFloatingCountdown(): void {
    this.isRunning = true;
    
    // 获取配置的抢票时间
    const ticketTime = this.getTicketTime();
    const now = new Date().getTime();
    let remaining = Math.floor((ticketTime - now) / 1000);
    
    if (remaining < 0) remaining = 0;
    
    this.timer = setInterval(() => {
      remaining--;
      
      const hours = Math.floor(remaining / 3600);
      const minutes = Math.floor((remaining % 3600) / 60);
      const seconds = remaining % 60;
      this.countdownText = 
        `${hours.toString().padStart(2, '0')}:${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`;
      
      if (remaining <= 0) {
        this.startGrabTicket();
      }
    }, 1000);
  }
  
  // 停止悬浮倒计时
  stopFloatingCountdown(): void {
    if (this.timer !== -1) {
      clearInterval(this.timer);
      this.timer = -1;
    }
    this.isRunning = false;
  }
  
  // 获取抢票时间
  getTicketTime(): number {
    // 从配置中获取
    const now = new Date();
    const target = new Date();
    target.setHours(10, 0, 0, 0);
    if (now > target) target.setDate(target.getDate() + 1);
    return target.getTime();
  }
  
  // 开始抢票
  startGrabTicket(): void {
    this.stopFloatingCountdown();
    
    // 启动抢票服务
    const want = {
      abilityName: 'TicketServiceAbility',
      action: 'grab_ticket'
    };
    context.startAbility(want);
    
    // 关闭悬浮窗
    context.terminateSelf();
  }
  
  build() {
    Column() {
      // 倒计时
      Text(this.countdownText)
        .fontSize(32)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')
        .margin({ bottom: 10 })
      
      // 状态提示
      Text('抢票倒计时')
        .fontSize(14)
        .fontColor('#CCCCCC')
      
      // 关闭按钮
      Button('关闭')
        .width(80)
        .height(36)
        .fontSize(14)
        .fontColor('#FFFFFF')
        .backgroundColor('#FF5722')
        .borderRadius(18)
        .margin({ top: 20 })
        .onClick(() => {
          this.stopFloatingCountdown();
          context.terminateSelf();
        })
    }
    .width(200)
    .height(150)
    .padding(20)
    .backgroundColor('#CC000000')
    .borderRadius(12)
  }
}
