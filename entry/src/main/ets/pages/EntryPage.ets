// EntryPage.ets - 主页面：倒计时 + 控制按钮

import router from '@ohos.router';

@Entry
@Component
struct EntryPage {
  // 抢票时间配置
  @State ticketHour: number = 10;
  @State ticketMinute: number = 0;
  @State ticketSecond: number = 0;
  
  // 倒计时状态
  @State countdownText: string = '--:--:--';
  @State isRunning: boolean = false;
  @State isCountingDown: boolean = false;
  @State remainingSeconds: number = 0;
  
  // 定时器引用
  private timer: number = -1;
  
  aboutToAppear(): void {
    // 从本地存储加载配置
    this.loadConfig();
  }
  
  aboutToDisappear(): void {
    this.stopTimer();
  }
  
  // 加载配置
  loadConfig(): void {
    try {
      const preferences = getContext(this).getPreferences('ticket_config', ContextPreferences.Mode.PRIVATE);
      preferences.getAll().then((result: Object) => {
        if (result['ticket_hour']) this.ticketHour = result['ticket_hour'];
        if (result['ticket_minute']) this.ticketMinute = result['ticket_minute'];
        if (result['ticket_second']) this.ticketSecond = result['ticket_second'];
      });
    } catch (e) {
      console.error('加载配置失败:', e);
    }
  }
  
  // 保存配置
  saveConfig(): void {
    try {
      const preferences = getContext(this).getPreferences('ticket_config', ContextPreferences.Mode.PRIVATE);
      preferences.put('ticket_hour', this.ticketHour);
      preferences.put('ticket_minute', this.ticketMinute);
      preferences.put('ticket_second', this.ticketSecond);
      preferences.flush();
    } catch (e) {
      console.error('保存配置失败:', e);
    }
  }
  
  // 开始倒计时
  startCountdown(): void {
    this.isRunning = true;
    this.isCountingDown = true;
    
    const now = new Date();
    const target = new Date();
    target.setHours(this.ticketHour, this.ticketMinute, this.ticketSecond, 0);
    
    if (now > target) {
      target.setDate(target.getDate() + 1);
    }
    
    this.remainingSeconds = Math.floor((target.getTime() - now.getTime()) / 1000);
    
    this.timer = setInterval(() => {
      this.remainingSeconds--;
      
      const hours = Math.floor(this.remainingSeconds / 3600);
      const minutes = Math.floor((this.remainingSeconds % 3600) / 60);
      const seconds = this.remainingSeconds % 60;
      this.countdownText = 
        `${hours.toString().padStart(2, '0')}:${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`;
      
      if (this.remainingSeconds <= 0) {
        this.startTicketGrabbing();
      }
    }, 1000);
    
    // 启动后台服务
    this.startBackgroundService();
  }
  
  // 停止倒计时
  stopCountdown(): void {
    this.stopTimer();
    this.isRunning = false;
    this.isCountingDown = false;
    this.countdownText = '--:--:--';
  }
  
  stopTimer(): void {
    if (this.timer !== -1) {
      clearInterval(this.timer);
      this.timer = -1;
    }
  }
  
  // 启动后台服务
  startBackgroundService(): void {
    const want = {
      abilityName: 'TicketServiceAbility',
      action: 'start_ticket_grabbing'
    };
    context.startAbility(want);
  }
  
  // 开始抢票
  startTicketGrabbing(): void {
    this.stopTimer();
    this.isCountingDown = false;
    
    // 启动抢票服务
    const want = {
      abilityName: 'TicketServiceAbility',
      action: 'grab_ticket'
    };
    context.startAbility(want);
    
    // 显示提示
    const toast = ToastOption({
      message: '开始抢票中...',
      duration: 2000
    });
    showToast(toast);
  }
  
  // 显示悬浮窗
  showFloatWindow(): void {
    const want = {
      abilityName: 'FloatWindowAbility'
    };
    context.startAbility(want);
  }
  
  build() {
    Column() {
      // 标题
      Text('大麦抢票助手')
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1A73E8')
        .margin({ top: 40, bottom: 30 })
      
      // 倒计时显示
      if (this.isCountingDown) {
        Text(this.countdownText)
          .fontSize(48)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FF5722')
          .margin({ bottom: 40 })
          .width('100%')
          .textAlign(TextAlign.Center)
      } else {
        Text('等待开始')
          .fontSize(24)
          .fontColor('#666666')
          .margin({ bottom: 40 })
      }
      
      // 时间配置区域
      Column() {
        Text('抢票时间设置')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333333')
          .margin({ bottom: 20 })
        
        Row() {
          Column() {
            Text('时')
              .fontSize(12)
              .fontColor('#666666')
            Picker({ value: this.ticketHour, min: 0, max: 23 })
              .pickerMode(PickerMode.Normal)
              .onChange((value: number) => {
                this.ticketHour = value;
                this.saveConfig();
              })
          }
          .width(100)
          
          Text(':')
            .fontSize(24)
            .fontColor('#333333')
            .margin({ left: 10, right: 10 })
          
          Column() {
            Text('分')
              .fontSize(12)
              .fontColor('#666666')
            Picker({ value: this.ticketMinute, min: 0, max: 59 })
              .pickerMode(PickerMode.Normal)
              .onChange((value: number) => {
                this.ticketMinute = value;
                this.saveConfig();
              })
          }
          .width(100)
          
          Text(':')
            .fontSize(24)
            .fontColor('#333333')
            .margin({ left: 10, right: 10 })
          
          Column() {
            Text('秒')
              .fontSize(12)
              .fontColor('#666666')
            Picker({ value: this.ticketSecond, min: 0, max: 59 })
              .pickerMode(PickerMode.Normal)
              .onChange((value: number) => {
                this.ticketSecond = value;
                this.saveConfig();
              })
          }
          .width(100)
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .margin({ top: 20 })
      }
      .width('80%')
      .padding(20)
      .backgroundColor('#F5F5F5')
      .borderRadius(12)
      .margin({ bottom: 30 })
      
      // 控制按钮
      if (!this.isRunning) {
        Button('开始倒计时')
          .width('80%')
          .height(50)
          .fontSize(18)
          .fontColor('#FFFFFF')
          .backgroundColor('#1A73E8')
          .borderRadius(25)
          .onClick(() => {
            this.startCountdown();
          })
      } else {
        Button('停止')
          .width('80%')
          .height(50)
          .fontSize(18)
          .fontColor('#FFFFFF')
          .backgroundColor('#FF5722')
          .borderRadius(25)
          .margin({ bottom: 15 })
          .onClick(() => {
            this.stopCountdown();
          })
        
        Button('显示悬浮窗')
          .width('80%')
          .height(50)
          .fontSize(18)
          .fontColor('#FFFFFF')
          .backgroundColor('#4CAF50')
          .borderRadius(25)
          .onClick(() => {
            this.showFloatWindow();
          })
      }
      
      // 说明文字
      Text('提示：请确保大麦 App 已登录\n开启悬浮窗权限以获得最佳体验')
        .fontSize(12)
        .fontColor('#999999')
        .margin({ top: 30 })
        .textAlign(TextAlign.Center)
        .width('80%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }
}
