// 简化版主页面 - 只显示倒计时和点击坐标设置
// EntryPage_Simple.ets

import { promptAction } from '@kit.ArkUI';

@Entry
@Component
struct EntryPage_Simple {
  // 抢票时间
  @State hour: number = 10;
  @State minute: number = 0;
  @State second: number = 0;
  
  // 倒计时
  @State countdown: string = '--:--:--';
  @State isRunning: boolean = false;
  
  // 点击配置
  @State clickX: number = 630;   // 点击 X 坐标
  @State clickY: number = 2600;  // 点击 Y 坐标
  @State clickInterval: number = 50;  // 点击间隔 (毫秒)
  @State clickCount: number = 3;  // 连续点击次数
  
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
        if (data['click_x']) this.clickX = data['click_x'];
        if (data['click_y']) this.clickY = data['click_y'];
        if (data['click_interval']) this.clickInterval = data['click_interval'];
        if (data['click_count']) this.clickCount = data['click_count'];
      });
    } catch (e) {
      console.error('加载配置失败:', e);
    }
  }
  
  // 保存配置
  saveConfig(): void {
    try {
      const preferences = getContext(this).getPreferences('config', ContextPreferences.Mode.PRIVATE);
      preferences.put('hour', this.hour);
      preferences.put('minute', this.minute);
      preferences.put('second', this.second);
      preferences.put('click_x', this.clickX);
      preferences.put('click_y', this.clickY);
      preferences.put('click_interval', this.clickInterval);
      preferences.put('click_count', this.clickCount);
      preferences.flush();
    } catch (e) {
      console.error('保存配置失败:', e);
    }
  }
  
  // 开始倒计时
  start(): void {
    this.isRunning = true;
    
    const now = new Date();
    const target = new Date();
    target.setHours(this.hour, this.minute, this.second, 0);
    
    if (now > target) {
      target.setDate(target.getDate() + 1);
    }
    
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
  
  // 停止
  stop(): void {
    if (this.timer !== -1) {
      clearInterval(this.timer);
      this.timer = -1;
    }
    if (this.clickTimer !== -1) {
      clearInterval(this.clickTimer);
      this.clickTimer = -1;
    }
    this.isRunning = false;
    this.countdown = '--:--:--';
  }
  
  // 自动点击
  autoClick(): void {
    console.info('开始自动点击');
    
    let count = 0;
    this.clickTimer = setInterval(() => {
      if (count >= this.clickCount) {
        clearInterval(this.clickTimer);
        this.clickTimer = -1;
        console.info('点击完成');
        return;
      }
      
      // 发送点击事件
      this.simulateTap(this.clickX, this.clickY);
      console.info(`点击 ${count + 1}/${this.clickCount}`);
      count++;
    }, this.clickInterval);
  }
  
  // 模拟点击（需要系统权限）
  simulateTap(x: number, y: number): void {
    // 方案 1: 使用 input 事件（需要无障碍权限）
    // 方案 2: 使用系统 API
    // 方案 3: 通过 ADB（需要电脑连接）
    
    // 这里使用方案 2 - 系统输入事件
    try {
      const inputEvent = {
        type: 'tap',
        x: x,
        y: y
      };
      // 注意：实际实现需要申请系统权限
      console.info(`模拟点击 (${x}, ${y})`);
    } catch (e) {
      console.error('点击失败:', e);
    }
  }
  
  // 校准模式 - 点击屏幕任意位置记录坐标
  startCalibration(): void {
    promptAction.showToast({
      message: '点击屏幕任意位置记录坐标',
      duration: 2000
    });
    // 进入校准模式，用户点击后记录坐标
  }
  
  build() {
    Column() {
      // 标题
      Text('快速抢票助手')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1A73E8')
        .margin({ top: 40, bottom: 30 })
      
      // 倒计时
      Text(this.countdown)
        .fontSize(56)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.isRunning ? '#FF5722' : '#666666')
        .margin({ bottom: 30 })
      
      // 时间设置
      if (!this.isRunning) {
        Row() {
          Text('抢票时间:')
            .fontSize(16)
            .fontColor('#333333')
          
          Picker({ value: this.hour, min: 0, max: 23 })
            .onChange((v) => { this.hour = v; this.saveConfig() })
          
          Text(':')
          Picker({ value: this.minute, min: 0, max: 59 })
            .onChange((v) => { this.minute = v; this.saveConfig() })
          
          Text(':')
          Picker({ value: this.second, min: 0, max: 59 })
            .onChange((v) => { this.second = v; this.saveConfig() })
        }
        .margin({ bottom: 30 })
      }
      
      // 点击配置
      Column() {
        Text('点击配置')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333333')
          .margin({ bottom: 15 })
        
        Row() {
          Text('X:')
          Input({ text: this.clickX.toString() })
            .width(100)
            .onChange((v) => { this.clickX = parseInt(v) || 630 })
          
          Text('Y:')
          Input({ text: this.clickY.toString() })
            .width(100)
            .onChange((v) => { this.clickY = parseInt(v) || 2600 })
        }
        .margin({ bottom: 10 })
        
        Row() {
          Text('间隔 (ms):')
          Input({ text: this.clickInterval.toString() })
            .width(100)
            .onChange((v) => { this.clickInterval = parseInt(v) || 50 })
          
          Text('次数:')
          Input({ text: this.clickCount.toString() })
            .width(60)
            .onChange((v) => { this.clickCount = parseInt(v) || 3 })
        }
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
          .height(50)
          .fontSize(18)
          .backgroundColor('#1A73E8')
          .fontColor('#FFFFFF')
          .borderRadius(25)
          .onClick(() => this.start())
      } else {
        Button('停止')
          .width('80%')
          .height(50)
          .fontSize(18)
          .backgroundColor('#FF5722')
          .fontColor('#FFFFFF')
          .borderRadius(25)
          .onClick(() => this.stop())
      }
      
      // 说明
      Text('提示:\n1. 请先手动打开大麦 App\n2. 设置好点击坐标\n3. 倒计时结束自动点击')
        .fontSize(12)
        .fontColor('#999999')
        .margin({ top: 20 })
        .textAlign(TextAlign.Center)
        .width('80%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }
}
