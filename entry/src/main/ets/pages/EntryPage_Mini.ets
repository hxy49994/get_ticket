// 极简版 - 只点击「立即购买」按钮
// EntryPage_Mini.ets

@Entry
@Component
struct EntryPage_Mini {
  // 抢票时间
  @State hour: number = 10;
  @State minute: number = 0;
  @State second: number = 0;
  
  // 倒计时
  @State countdown: string = '--:--:--';
  @State isRunning: boolean = false;
  @State status: string = '等待开始';
  
  // 点击配置 - 步骤 5: 立即购买
  @State clickX: number = 630;   // 屏幕水平中间
  @State clickY: number = 2600;  // 屏幕底部「立即购买」按钮
  @State clickInterval: number = 30;  // 30ms 间隔（超快）
  @State clickCount: number = 5;      // 点击 5 次
  
  // 定时器
  private timer: number = -1;
  private clickTimer: number = -1;
  
  aboutToAppear(): void {
    this.loadConfig();
  }
  
  aboutToDisappear(): void {
    this.stop();
  }
  
  // 加载配置
  loadConfig(): void {
    try {
      const preferences = getContext(this).getPreferences('config', ContextPreferences.Mode.PRIVATE);
      preferences.getAll().then((data: Object) => {
        if (data['hour']) this.hour = data['hour'];
        if (data['minute']) this.minute = data['minute'];
        if (data['second']) this.second = data['second'];
        if (data['click_y']) this.clickY = data['click_y'];
        if (data['click_interval']) this.clickInterval = data['click_interval'];
        if (data['click_count']) this.clickCount = data['click_count'];
      });
    } catch (e) { console.error(e); }
  }
  
  saveConfig(): void {
    try {
      const preferences = getContext(this).getPreferences('config', ContextPreferences.Mode.PRIVATE);
      preferences.put('hour', this.hour);
      preferences.put('minute', this.minute);
      preferences.put('second', this.second);
      preferences.put('click_y', this.clickY);
      preferences.put('click_interval', this.clickInterval);
      preferences.put('click_count', this.clickCount);
      preferences.flush();
    } catch (e) { console.error(e); }
  }
  
  start(): void {
    this.isRunning = true;
    this.status = '倒计时中...';
    
    const now = new Date();
    const target = new Date();
    target.setHours(this.hour, this.minute, this.second, 0);
    if (now > target) target.setDate(target.getDate() + 1);
    
    let remaining = Math.floor((target.getTime() - now.getTime()) / 1000);
    
    this.timer = setInterval(() => {
      remaining--;
      
      const h = Math.floor(remaining / 3600);
      const m = Math.floor((remaining % 3600) / 60);
      const s = remaining % 60;
      this.countdown = `${h.toString().padStart(2, '0')}:${m.toString().padStart(2, '0')}:${s.toString().padStart(2, '0')}`;
      
      if (remaining <= 0) {
        this.stop();
        this.autoClick();
      }
    }, 1000);
    
    this.saveConfig();
  }
  
  stop(): void {
    if (this.timer !== -1) { clearInterval(this.timer); this.timer = -1; }
    if (this.clickTimer !== -1) { clearInterval(this.clickTimer); this.clickTimer = -1; }
    this.isRunning = false;
    this.countdown = '--:--:--';
    this.status = '等待开始';
  }
  
  autoClick(): void {
    this.status = '🚀 点击中...';
    console.info('=== 开始自动点击 ===');
    
    let count = 0;
    this.clickTimer = setInterval(() => {
      if (count >= this.clickCount) {
        clearInterval(this.clickTimer);
        this.clickTimer = -1;
        this.status = '✅ 点击完成';
        console.info('=== 点击完成 ===');
        return;
      }
      
      // 执行点击
      this.simulateTap(this.clickX, this.clickY);
      this.status = `🚀 点击 ${count + 1}/${this.clickCount}`;
      console.info(`点击 ${count + 1}/${this.clickCount} @ (${this.clickX}, ${this.clickY})`);
      count++;
    }, this.clickInterval);
  }
  
  // 模拟点击 - 使用系统输入事件
  simulateTap(x: number, y: number): void {
    // 方案 1: 使用系统输入事件 (需要权限)
    // 方案 2: 通过 ADB (需要电脑连接)
    // 方案 3: 使用无障碍服务
    
    // 这里使用 console 输出，实际需要在无障碍服务中实现
    console.info(`[Tap] X=${x}, Y=${y}`);
  }
  
  build() {
    Column() {
      // 标题
      Text('极简抢票助手')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1A73E8')
        .margin({ top: 40, bottom: 10 })
      
      Text('只点击「立即购买」按钮')
        .fontSize(14)
        .fontColor('#666666')
        .margin({ bottom: 30 })
      
      // 倒计时（大字显示）
      Text(this.countdown)
        .fontSize(64)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.isRunning ? '#FF5722' : '#333333')
        .margin({ bottom: 10 })
      
      // 状态
      Text(this.status)
        .fontSize(18)
        .fontColor(this.isRunning ? '#FF9800' : '#999999')
        .margin({ bottom: 30 })
      
      // 时间设置
      if (!this.isRunning) {
        Row() {
          Text('抢票时间:')
            .fontSize(16)
            .fontColor('#333333')
          
          Picker({ value: this.hour, min: 0, max: 23 })
            .pickerMode(PickerMode.Normal)
            .onChange((v) => { this.hour = v; this.saveConfig() })
          
          Text(':').fontColor('#333333')
          Picker({ value: this.minute, min: 0, max: 59 })
            .pickerMode(PickerMode.Normal)
            .onChange((v) => { this.minute = v; this.saveConfig() })
          
          Text(':').fontColor('#333333')
          Picker({ value: this.second, min: 0, max: 59 })
            .pickerMode(PickerMode.Normal)
            .onChange((v) => { this.second = v; this.saveConfig() })
        }
        .margin({ bottom: 30 })
      }
      
      // 点击配置（简化）
      Column() {
        Text('点击配置 (步骤 5: 立即购买)')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333333')
          .margin({ bottom: 10 })
        
        Row() {
          Text('Y 坐标:')
            .fontColor('#666666')
          Input({ text: this.clickY.toString() })
            .width(120)
            .fontSize(14)
            .onChange((v) => { this.clickY = parseInt(v) || 2600; this.saveConfig() })
        }
        .margin({ bottom: 8 })
        
        Row() {
          Text('间隔:')
            .fontColor('#666666')
          Input({ text: this.clickInterval.toString() })
            .width(80)
            .fontSize(14)
            .onChange((v) => { this.clickInterval = parseInt(v) || 30; this.saveConfig() })
          Text('ms').fontColor('#999999')
        }
        .margin({ bottom: 8 })
        
        Row() {
          Text('次数:')
            .fontColor('#666666')
          Input({ text: this.clickCount.toString() })
            .width(60)
            .fontSize(14)
            .onChange((v) => { this.clickCount = parseInt(v) || 5; this.saveConfig() })
        }
        
        // 说明
        Text('X 坐标固定：630 (屏幕中间)')
          .fontSize(12)
          .fontColor('#999999')
          .margin({ top: 10 })
      }
      .width('100%')
      .padding(15)
      .backgroundColor('#F5F5F5')
      .borderRadius(10)
      .margin({ bottom: 30 })
      
      // 控制按钮
      if (!this.isRunning) {
        Button('开始倒计时')
          .width('80%')
          .height(55)
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .backgroundColor('#1A73E8')
          .fontColor('#FFFFFF')
          .borderRadius(28)
          .onClick(() => this.start())
      } else {
        Button('停止')
          .width('80%')
          .height(55)
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .backgroundColor('#FF5722')
          .fontColor('#FFFFFF')
          .borderRadius(28)
          .onClick(() => this.stop())
      }
      
      // 提示
      Text('使用流程:\n1. 手动打开大麦 App\n2. 进入「立即购买」页面\n3. 点击开始倒计时\n4. 等待到点自动点击')
        .fontSize(12)
        .fontColor('#999999')
        .margin({ top: 20 })
        .textAlign(TextAlign.Center)
        .width('85%')
        .lineHeight(20)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }
}
