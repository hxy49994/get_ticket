// TicketWorkExtension.ets - 后台工作扩展 (WorkScheduler)

import workScheduler from '@ohos.workScheduler';

@Entry
@Component
struct TicketWorkExtension {
  private workId: string = 'ticket_grab_work';
  
  aboutToAppear(): void {
    this.scheduleTicketWork();
  }
  
  // 调度抢票任务
  scheduleTicketWork(): void {
    console.info('调度抢票任务');
    
    const workRequest = {
      name: 'TicketGrabWork',
      tag: this.workId,
      constraints: {
        networkType: workScheduler.NetworkType.CONNECTED,
        requiresCharging: false,
        requiresDeviceIdle: false,
        requiresStorageNotLow: false
      },
      input: {
        ticket_time: this.getTicketTime(),
        retry_count: 5
      }
    };
    
    // 周期性调度
    workScheduler.schedulePeriodicWork(workRequest, 3600000).then(() => {
      console.info('任务调度成功');
    }).catch((err) => {
      console.error('任务调度失败:', err);
    });
  }
  
  // 获取抢票时间
  getTicketTime(): number {
    // 从本地配置获取抢票时间
    const now = new Date();
    return now.getTime();
  }
  
  // 执行抢票工作
  doWork(): void {
    console.info('执行抢票工作');
    
    // 检查是否到达抢票时间
    const ticketTime = this.getTicketTime();
    const now = Date.now();
    
    if (Math.abs(now - ticketTime) < 60000) { // 1 分钟内
      this.executeTicketGrab();
    }
  }
  
  // 执行抢票
  executeTicketGrab(): void {
    console.info('执行抢票');
    // 启动抢票流程
  }
  
  // 取消任务
  cancelWork(): void {
    workScheduler.cancelByTag(this.workId).then(() => {
      console.info('任务已取消');
    }).catch((err) => {
      console.error('取消任务失败:', err);
    });
  }
}
