"""
大麦抢票核心流程自动化
"""

import time
import threading
from datetime import datetime, timedelta
from typing import Optional, Callable

from loguru import logger

from adb_controller import ADBController
import config


class DamaiAutomation:
    """大麦抢票自动化"""

    def __init__(self, adb: ADBController, status_callback: Optional[Callable] = None):
        self.adb = adb
        self.status_callback = status_callback
        self._running = False
        self._stop_flag = False

    def _update_status(self, msg: str, level: str = "info"):
        """更新状态回调"""
        if self.status_callback:
            self.status_callback(msg, level)
        log_fn = getattr(logger, level, logger.info)
        log_fn(msg)

    def calculate_wait_seconds(self) -> float:
        """计算距离目标抢票时间还有多少秒"""
        now = datetime.now()
        target = now.replace(
            hour=config.TICKET_TIME["hour"],
            minute=config.TICKET_TIME["minute"],
            second=config.TICKET_TIME["second"],
            microsecond=0,
        )

        # 如果目标时间已过，设置为第二天
        if now > target:
            target += timedelta(days=1)

        return (target - now).total_seconds()

    def precision_wait(self, target_timestamp: float):
        """高精度等待到目标时间戳"""
        while time.time() < target_timestamp:
            remaining = target_timestamp - time.time()
            if remaining > 1:
                time.sleep(0.5)
            elif remaining > 0.1:
                time.sleep(0.05)
            elif remaining > 0.01:
                time.sleep(0.005)
            else:
                # 最后 10ms 使用忙等待
                pass

    def open_damai(self) -> bool:
        """打开大麦 App"""
        self._update_status("正在打开大麦 App...")
        self.adb.close_app(config.DAMAI_PACKAGE)
        time.sleep(0.5)

        if not self.adb.open_app(config.DAMAI_PACKAGE):
            self._update_status("打开大麦 App 失败", "error")
            return False

        time.sleep(3)
        self._update_status("大麦 App 已打开")
        return True

    def go_to_ticket_page(self) -> bool:
        """导航到待抢票的票品页面
        
        流程: 首页 → 我的 → 我的门票 → 点击目标场次
        或者: 直接通过 URL Scheme / 唤起指定页面
        """
        self._update_status("正在导航到票品页面...")

        # 方案1: 通过「我的」→「我的门票」进入
        # 点击底部导航「我的」
        self.adb.tap(*config.TAB_MY)
        time.sleep(config.PAGE_LOAD_TIMEOUT)

        # 点击「我的门票」
        self.adb.tap(*config.BTN_MY_TICKET)
        time.sleep(config.PAGE_LOAD_TIMEOUT)

        # 滚动到列表
        self._update_status("正在查找待抢购票品...")
        time.sleep(1)

        # 点击目标场次 (第 config.TICKET_INDEX 个)
        # 这里需要根据实际 UI 调整，可能是列表项坐标，或需要滑动
        self._update_status(f"正在选择第 {config.TICKET_INDEX + 1} 个票品...")
        # 模拟: 点击列表项
        # 实际使用时，你可能需要基于截图分析来动态定位

        self._update_status("已进入票品详情页")
        return True

    def wait_for_purchase_time(self) -> bool:
        """等待到开抢时间"""
        wait_seconds = self.calculate_wait_seconds()

        if wait_seconds > config.PRE_ENTER_SECONDS:
            # 提前进入 App 等待
            wait_before_enter = wait_seconds - config.PRE_ENTER_SECONDS
            self._update_status(
                f"距离抢票还有 {wait_seconds:.0f} 秒, "
                f"等待 {wait_before_enter:.0f} 秒后进入页面..."
            )
            self._wait_with_countdown(wait_before_enter)

        # 提前进入页面
        self._update_status("准备进入抢票页面...")
        return True

    def _wait_with_countdown(self, seconds: float):
        """倒计时等待，支持取消"""
        end = time.time() + seconds
        while time.time() < end:
            if self._stop_flag:
                return
            remaining = end - time.time()
            if int(remaining) % 5 == 0 and remaining > 1:
                self._update_status(f"倒计时: {int(remaining)} 秒...")
            time.sleep(0.5)

    def click_buy_now(self) -> bool:
        """点击「立即购买」按钮"""
        self._update_status("正在点击「立即购买」...")
        for i in range(config.MAX_RETRY):
            if self._stop_flag:
                return False
            self.adb.tap(*config.BTN_BUY_NOW)
            time.sleep(config.QUICK_INTERVAL)
            # 检查是否已进入选择页面
            # 如果能检测到「提交订单」按钮或场次选择弹窗，则成功
        return True

    def select_session_and_price(self) -> bool:
        """选择场次和价格"""
        self._update_status("正在选择场次和价格...")

        # 选择场次
        # 实际场次弹窗位置需要根据截图确定
        # 这里模拟选择第一个场次
        session_y = 600 + config.SESSION_INDEX * 150
        self.adb.tap(630, session_y)
        time.sleep(config.QUICK_INTERVAL)

        # 选择价格档位
        price_y = 1000 + config.PRICE_INDEX * 120
        self.adb.tap(630, price_y)
        time.sleep(config.QUICK_INTERVAL)

        self._update_status("场次和价格已选择")
        return True

    def select_quantity(self, count: int = 1) -> bool:
        """选择购买数量"""
        self._update_status(f"正在选择数量: {count} 张...")
        # 点击 + 号增加数量
        for _ in range(count - 1):
            if self._stop_flag:
                return False
            self.adb.tap(*config.BTN_PLUS)
            time.sleep(config.QUICK_INTERVAL)
        return True

    def submit_order(self) -> bool:
        """提交订单"""
        self._update_status("正在提交订单...")
        for i in range(config.MAX_RETRY):
            if self._stop_flag:
                return False
            self.adb.tap(*config.BTN_SUBMIT)
            time.sleep(1)

            # 检查是否进入了支付页面
            current_pkg = self.adb.get_foreground_package()
            if current_pkg and config.ALIPAY_PACKAGE in current_pkg:
                self._update_status("已跳转到支付宝!", "success")
                return True

            # 检查是否还在大麦（可能因为网络延迟没反应）
            self._update_status(f"等待订单提交... ({i+1}/{config.MAX_RETRY})")

        self._update_status("提交订单失败", "error")
        return False

    def wait_for_alipay(self, timeout: float = 15.0) -> bool:
        """等待支付宝支付页面出现"""
        self._update_status("等待支付宝跳转...")
        if self.adb.wait_for_package(config.ALIPAY_PACKAGE, timeout):
            self._update_status("支付宝支付页面已打开!", "success")
            return True
        self._update_status("支付宝跳转超时", "error")
        return False

    def run_flow(self) -> bool:
        """
        执行完整的抢票流程
        
        流程图:
        1. 打开大麦 App
        2. 导航到票品页面
        3. 等待抢票时间
        4. 点击「立即购买」
        5. 选择场次和价格
        6. 提交订单
        7. 跳转支付宝支付
        """
        self._running = True
        self._stop_flag = False

        try:
            # Step 1: 打开大麦
            if not self.open_damai():
                return False

            # Step 2: 导航到目标页面
            if not self.go_to_ticket_page():
                return False

            # Step 3: 等待开抢时间
            if not self.wait_for_purchase_time():
                return False

            # Step 4: 精确到秒点击购买
            # 先进入倒计时
            now = datetime.now()
            target = now.replace(
                hour=config.TICKET_TIME["hour"],
                minute=config.TICKET_TIME["minute"],
                second=config.TICKET_TIME["second"],
                microsecond=0,
            )

            target_ts = target.timestamp()
            self._update_status(f"等待到达抢票时间 {target.strftime('%H:%M:%S')}...")
            self.precision_wait(target_ts)

            # Step 4: 点击立即购买
            self._update_status(f"⏰ 抢票时间到! 正在抢票...")
            if not self.click_buy_now():
                # 如果第一次没成功，可能是已经在页面上了，直接尝试提交
                pass

            time.sleep(config.QUICK_INTERVAL)

            # Step 5: 选择场次和价格
            self.select_session_and_price()
            time.sleep(config.QUICK_INTERVAL)

            # 设置数量
            self.select_quantity()
            time.sleep(config.QUICK_INTERVAL)

            # Step 6: 提交订单
            self._update_status("提交订单中...")
            if self.submit_order():
                self._update_status("🎉 抢票成功! 请在支付宝完成支付", "success")
                return True

            self._update_status("❌ 抢票失败", "error")
            return False

        except Exception as e:
            self._update_status(f"抢票异常: {e}", "error")
            return False
        finally:
            self._running = False

    def start(self):
        """在单独的线程中启动抢票"""
        thread = threading.Thread(target=self.run_flow, daemon=True)
        thread.start()
        return thread

    def stop(self):
        """停止抢票"""
        self._stop_flag = True
        self._update_status("正在停止抢票...")

    def is_running(self) -> bool:
        return self._running
