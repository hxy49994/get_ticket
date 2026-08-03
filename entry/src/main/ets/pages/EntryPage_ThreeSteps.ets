// 三步点击版 - 立即购票 → 确认场次 → 立即提交
// EntryPage_ThreeSteps.ets

@Entry
@Component
struct EntryPage_ThreeSteps {
  // 抢票时间
  @State hour: number = 10;
  @State minute: number = 0;
  @State second: number = 0;
  
  // 倒计时
  @State countdown: string = '--:--:--';
  @State isRunning: boolean = false;
  @State status: string = '等待开始';
  
  // 三步点击坐标配置
  @State step1Y: number = 2600;  // 步骤 1: 立即购票
  @State step2Y: number = 1800;  // 步骤 2: 确认场次（确定）
  @State step3Y: number = 2550;  // 步骤 3: 立即提交
  
  // 点击参数
  @State clickInterval: number = 500;  // 每步间隔 500ms（给页面加载时间）
  @State clickCount: number = 3;       // 每步点击 3 次
  
  // 定时器
  private timer: number = -1;
  private clickTimer: number = -1;
  
  aboutToAppear(): void {
    this.loadConfig();
  }
  
  aboutToDisappear(): void {
    this.stop();
  }
  
  loadConfig(): void {
    try {
      const preferences = getContext(this).getPreferences('config', ContextPreferences.Mode.PRIVATE);
      preferences.getAll().then((data: Object) => {
        if (data['hour']) this.hour = data['hour'];
        if (data['minute']) this.minute = data['minute'];
        if (data['second']) this.second = data['second'];
        if (data['step1_y']) this.step1Y = data['step1_y'];
        if (data['step2_y']) this.step2Y = data['step2_y'];
        if (data['step3_y']) this.step3Y = data['step3_y'];
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
      preferences.put('step1_y', this.step1Y);
      preferences.put('step2_y', this.step2Y);
      preferences.put('step3_y', this.step3Y);
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
        this.autoClickThreeSteps();
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
  
  // 三步自动点击
  autoClickThreeSteps(): void {
    console.info('=== 开始三步点击 ===');
    this.status = '🚀 步骤 1: 立即购票';
    
    let currentStep = 1;
    let clickCount = 0;
    
    this.clickTimer = setInterval(() => {
      if (currentStep > 3) {
        // 三步完成
        clearInterval(this.clickTimer);
        this.clickTimer = -1;
        this.status = '✅ 三步点击完成';
        console.info('=== 三步点击完成 ===');
        return;
      }
      
      // 当前步骤点击
      if (clickCount < this.clickCount) {
        // 执行点击
        let y = 0;
        let stepName = '';
        
        if (currentStep === 1) {
          y = this.step1Y;
          stepName = '立即购票';
        } else if (currentStep === 2) {
          y = this.step2Y;
          stepName = '确认场次';
        } else {
          y = this.step3Y;
          stepName = '立即提交';
        }
        
        this.simulateTap(630, y);
        clickCount++;
        this.status = `🚀 步骤${currentStep}: ${stepName} (${clickCount}/${this.clickCount})`;
        console.info(`步骤${currentStep} 点击 ${clickCount}/${this.clickCount} @ Y=${y}`);
      } else {
        // 当前步骤完成，进入下一步
        currentStep++;
        clickCount = 0;
        
        if (currentStep <= 3) {
          let nextStepName = '';
          if (currentStep === 1) nextStepName = '立即购票';
          else if (currentStep === 2) nextStepName = '确认场次';
          else nextStepName = '立即提交';
          
          this.status = `⏳ 等待 ${this.clickInterval}ms → 步骤${currentStep}: ${nextStepName}`;
          console.info(`进入步骤${currentStep}: ${nextStepName}`);
        }
      }
    }, this.clickInterval);
  }
  
  simulateTap(x: number, y: number): void {
    console.info(`[Tap] X=${x}, Y=${y}`);
  }
  
  build() {
    Column() {
      // 标题
      Text('三步抢票助手')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1A73E8')
        .margin({ top: 40, bottom: 5 })
      
      Text('立即购票 → 确认场次 → 立即提交')
        .fontSize(14)
        .fontColor('#666666')
        .margin({ bottom: 20 })
      
      // 倒计时
      Text(this.countdown)
        .fontSize(64)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.isRunning ? '#FF5722' : '#333333')
        .margin({ bottom: 5 })
      
      // 状态
      Text(this.status)
        .fontSize(16)
        .fontColor(this.isRunning ? '#FF9800' : '#999999')
        .margin({ bottom: 25 })
      
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
        .margin({ bottom: 25 })
      }
      
      // 三步坐标配置
      Column() {
        Text('三步点击坐标配置')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333333')
          .margin({ bottom: 12 })
        
        // 步骤 1
        Row() {
          Text('1. 立即购票 Y:')
            .fontSize(13)
            .fontColor('#666666')
            .width(100)
          Input({ text: this.step1Y.toString() })
            .width(100)
            .fontSize(13)
            .onChange((v) => { this.step1Y = parseInt(v) || 2600; this.saveConfig() })
        }
        .margin({ bottom: 8 })
        
        // 步骤 2
        Row() {
          Text('2. 确认场次 Y:')
            .fontSize(13)
            .fontColor('#666666')
            .width(100)
          Input({ text: this.step2Y.toString() })
            .width(100)
            .fontSize(13)
            .onChange((v) => { this.step2Y = parseInt(v) || 1800; this.saveConfig() })
        }
        .margin({ bottom: 8 })
        
        // 步骤 3
        Row() {
          Text('3. 立即提交 Y:')
            .fontSize(13)
            .fontColor('#666666')
            .width(100)
          Input({ text: this.step3Y.toString() })
            .width(100)
            .fontSize(13)
            .onChange((v) => { this.step3Y = parseInt(v) || 2550; this.saveConfig() })
        }
        .margin({ bottom: 15 })
        
        // 点击参数
        Text('点击参数')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333333')
          .margin({ bottom: 8 })
        
        Row() {
          Text('间隔:')
            .fontSize(13)
            .fontColor('#666666')
          Input({ text: this.clickInterval.toString() })
            .width(80)
            .fontSize(13)
            .onChange((v) => { this.clickInterval = parseInt(v) || 500; this.saveConfig() })
          Text('ms').fontColor('#999999')
        }
        .margin({ bottom: 5 })
        
        Row() {
          Text('每步次数:')
            .fontSize(13)
            .fontColor('#666666')
          Input({ text: this.clickCount.toString() })
            .width(60)
            .fontSize(13)
            .onChange((v) => { this.clickCount = parseInt(v) || 3; this.saveConfig() })
        }
        
        // 说明
        Text('X 坐标固定：630 (屏幕中间)')
          .fontSize(11)
          .fontColor('#999999')
          .margin({ top: 10 })
      }
      .width('100%')
      .padding(15)
      .backgroundColor('#F5F5F5')
      .borderRadius(10)
      .margin({ bottom: 25 })
      
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
      
      // 使用流程
      Text('使用流程:\n1. 手动打开大麦 App\n2. 到达「立即购票」页面\n3. 点击开始倒计时\n4. 自动执行三步点击')
        .fontSize(12)
        .fontColor('#999999')
        .margin({ top: 15 })
        .textAlign(TextAlign.Center)
        .width('85%')
        .lineHeight(18)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }
}
