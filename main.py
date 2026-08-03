"""
大麦抢票自动化 - 主入口

运行方式:
    python main.py              # 交互模式
    python main.py --auto       # 自动模式 (直接开始抢票)

使用前:
    1. 修改 config.py 中的抢票配置
    2. USB 连接华为 Mate60 Pro
    3. 开启 USB 调试
    4. 确保大麦 App 已登录
"""

import sys
import time
import threading
from datetime import datetime

from loguru import logger

from adb_controller import ADBController
from damai_automation import DamaiAutomation
import config


class TicketTool:
    """主控台"""

    def __init__(self):
        self.adb = ADBController()
        self.automation: DamaiAutomation = DamaiAutomation(
            self.adb, status_callback=self._on_status
        )

        # 控制台输出锁
        self._print_lock = threading.Lock()

    def _on_status(self, msg: str, level: str = "info"):
        """状态更新回调"""
        with self._print_lock:
            timestamp = datetime.now().strftime("%H:%M:%S.%f")[:12]
            prefix = {
                "info": "  INFO",
                "success": " ✅",
                "error": " ❌",
                "warning": " ⚠",
            }.get(level, "  INFO")
            print(f"[{timestamp}] {prefix} {msg}")

    def print_header(self):
        """打印欢迎信息"""
        print("=" * 55)
        print("  大麦抢票自动化工具 v1.0")
        print("  适用设备: 华为 Mate60 Pro")
        print(f"  抢票时间: {config.TICKET_TIME['hour']:02d}:{config.TICKET_TIME['minute']:02d}:{config.TICKET_TIME['second']:02d}")
        print("=" * 55)
        print()

    def print_menu(self):
        """打印菜单"""
        print()
        print("  [1] 连接设备")
        print("  [2] 测试截图")
        print("  [3] 获取当前屏幕信息")
        print("  [4] 校准坐标 (截图分析)")
        print("  [5] 开始抢票")
        print("  [6] 停止抢票")
        print("  [7] 打开大麦 App")
        print("  [8] 唤醒屏幕")
        print("  [0] 退出")
        print()

    def cmd_connect(self):
        """连接设备"""
        print("\n>> 正在检测设备...")
        devices = self.adb.get_devices()
        if devices:
            print(f"  发现设备: {devices}")
            if self.adb.connect_device():
                width, height = self.adb.get_screen_size()
                print(f"  屏幕分辨率: {width}×{height}")
                print(f"  config 配置: {config.DEVICE_WIDTH}×{config.DEVICE_HEIGHT}")
                if width != config.DEVICE_WIDTH or height != config.DEVICE_HEIGHT:
                    print("  ⚠ 分辨率与配置不一致，请更新 config.py")
                return
        print("  ❌ 未检测到设备")
        print("  请确保:")
        print("    1. USB 数据线已连接")
        print("    2. 手机上已开启「开发者选项」和「USB 调试」")
        print("    3. 如果是华为手机，还需要开启「仅充电模式下允许 ADB 调试」")

    def cmd_screenshot(self):
        """测试截图"""
        print("\n>> 正在截图...")
        path = f"screenshot_{datetime.now().strftime('%Y%m%d_%H%M%S')}.png"
        img = self.adb.screenshot(path)
        if img is not None:
            print(f"  ✅ 截图已保存: {path}")
            print(f"  图片尺寸: {img.shape[1]}×{img.shape[0]}")
        else:
            print("  ❌ 截图失败")

    def cmd_screen_info(self):
        """获取屏幕信息"""
        print("\n>> 屏幕信息:")
        pkg = self.adb.get_foreground_package()
        activity = self.adb.get_current_activity()
        width, height = self.adb.get_screen_size()
        print(f"  分辨率: {width}×{height}")
        print(f"  前台 App: {pkg}")
        print(f"  Activity: {activity}")

    def cmd_calibrate(self):
        """校准坐标"""
        print("\n>> 坐标校准工具")
        print("  操作说明:")
        print("    1. 打开大麦 App 并进入目标页面")
        print("    2. 程序会每隔 2 秒截一次图")
        print("    3. 截图保存在当前目录")
        print("    4. 用手工标注找到关键按钮坐标")
        print("    5. 更新 config.py 中的坐标值")
        print()
        input("  按 Enter 开始截图 (Ctrl+C 停止)...")

        count = 0
        try:
            while True:
                count += 1
                path = f"calibrate_{count:02d}.png"
                self.adb.screenshot(path)
                print(f"  📸 {path}")
                time.sleep(2)
        except KeyboardInterrupt:
            print(f"\n  共保存 {count} 张截图, 请查看并更新坐标")

    def cmd_start(self):
        """开始抢票"""
        if self.automation.is_running():
            print("  ⚠ 抢票正在进行中...")
            return

        # 检查设备连接
        if self.adb.device_serial is None:
            print("  ⚠ 请先连接设备")
            return

        # 检查屏幕状态
        if not self.adb.is_screen_on():
            print("  ⚠ 屏幕已关闭, 尝试唤醒...")
            self.adb.unlock_screen()

        # 计算倒计时
        now = datetime.now()
        target = now.replace(
            hour=config.TICKET_TIME["hour"],
            minute=config.TICKET_TIME["minute"],
            second=config.TICKET_TIME["second"],
            microsecond=0,
        )
        if now > target:
            target = target.replace(day=target.day + 1)

        wait_seconds = (target - now).total_seconds()

        if wait_seconds > 0:
            print(f"\n  🎯 抢票目标: {target.strftime('%Y-%m-%d %H:%M:%S')}")
            print(f"  ⏳ 距离抢票还有 {wait_seconds:.0f} 秒")
            print(f"  ⏰ 将在抢票前 {config.PRE_ENTER_SECONDS} 秒进入页面")
            print()
            confirm = input("  确认开始? (y/N): ")
            if confirm.lower() != "y":
                print("  已取消")
                return

        self.automation.start()

    def cmd_stop(self):
        """停止抢票"""
        if not self.automation.is_running():
            print("  ⚠ 没有正在运行的抢票任务")
            return
        self.automation.stop()
        print("  ⏹ 停止指令已发送")

    def cmd_open_damai(self):
        """打开大麦"""
        print("\n>> 正在打开大麦...")
        if self.adb.open_app(config.DAMAI_PACKAGE):
            print("  ✅ 大麦已打开")
        else:
            print("  ❌ 打开失败")

    def cmd_wake(self):
        """唤醒屏幕"""
        print("\n>> 正在唤醒屏幕...")
        self.adb.unlock_screen()
        print("  ✅ 已唤醒")

    def run_auto_mode(self):
        """自动模式 - 直接开始"""
        print("\n>> 自动模式启动...")
        if not self.adb.connect_device():
            print("  ❌ 设备连接失败，退出")
            return

        if not self.adb.is_screen_on():
            print("  ⚠ 屏幕关闭，尝试唤醒...")
            self.adb.unlock_screen()

        now = datetime.now()
        target = now.replace(
            hour=config.TICKET_TIME["hour"],
            minute=config.TICKET_TIME["minute"],
            second=config.TICKET_TIME["second"],
            microsecond=0,
        )
        if now > target:
            target = target.replace(day=target.day + 1)

        wait_seconds = (target - now).total_seconds()
        print(f"  🎯 抢票目标: {target.strftime('%Y-%m-%d %H:%M:%S')}")
        print(f"  ⏳ 距离抢票还有 {wait_seconds:.0f} 秒")

        self.automation.start()

        # 等待抢票完成
        try:
            while self.automation.is_running():
                time.sleep(1)
        except KeyboardInterrupt:
            self.automation.stop()
            print("\n  ⏹ 已停止")

    def run(self):
        """主循环"""
        self.print_header()

        # 自动尝试连接设备
        devices = self.adb.get_devices()
        if devices:
            print(f"  📱 发现设备: {devices}")
            self.adb.connect_device()
        else:
            print("  ⚠ 未检测到设备，请在菜单 [1] 中连接")
            print()

        while True:
            self.print_menu()
            choice = input("  请输入操作 [0-8]: ").strip()

            handlers = {
                "1": self.cmd_connect,
                "2": self.cmd_screenshot,
                "3": self.cmd_screen_info,
                "4": self.cmd_calibrate,
                "5": self.cmd_start,
                "6": self.cmd_stop,
                "7": self.cmd_open_damai,
                "8": self.cmd_wake,
                "0": lambda: sys.exit(0),
            }

            handler = handlers.get(choice)
            if handler:
                handler()
            else:
                print("  ⚠ 无效输入")


def main():
    if "--auto" in sys.argv:
        tool = TicketTool()
        tool.run_auto_mode()
    else:
        tool = TicketTool()
        tool.run()


if __name__ == "__main__":
    main()
