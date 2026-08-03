"""
ADB 控制器 - 封装所有 ADB 操作
兼容 macOS 和 Windows
"""

import subprocess
import time
import os
import platform
from typing import Optional, Tuple
from loguru import logger
import numpy as np
import cv2
from PIL import Image
import io

import config


class ADBController:
    """ADB 操作封装"""

    def __init__(self, device_serial: Optional[str] = None):
        self.device_serial = device_serial
        self._check_adb()

    def _run_adb(self, args: list[str]) -> Tuple[bool, str]:
        """执行 ADB 命令"""
        cmd = ["adb"]
        if self.device_serial:
            cmd += ["-s", self.device_serial]
        cmd += args

        try:
            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                timeout=30,
            )
            if result.returncode != 0:
                return False, result.stderr.strip()
            return True, result.stdout.strip()
        except subprocess.TimeoutExpired:
            return False, "ADB command timed out"
        except FileNotFoundError:
            return False, "ADB not found. Please install Android platform tools"
        except Exception as e:
            return False, str(e)

    def _check_adb(self):
        """检查 ADB 是否可用"""
        success, output = self._run_adb(["version"])
        if not success:
            logger.warning(f"ADB check failed: {output}")
            logger.warning(
                "Please install ADB:\n"
                "  macOS: brew install android-platform-tools\n"
                "  or download from: https://developer.android.com/studio/releases/platform-tools"
            )

    def get_devices(self) -> list[str]:
        """获取连接的设备列表"""
        success, output = self._run_adb(["devices"])
        if not success:
            return []

        devices = []
        for line in output.split("\n"):
            if line.strip() and "\tdevice" in line:
                devices.append(line.split("\t")[0])
        return devices

    def connect_device(self) -> bool:
        """连接设备，如果未指定 serial 则自动选择第一个"""
        devices = self.get_devices()
        if not devices:
            logger.error("未检测到连接的设备，请检查 USB 连接和 USB 调试")
            return False

        if self.device_serial is None:
            self.device_serial = devices[0]
            logger.info(f"自动选择设备: {self.device_serial}")
        elif self.device_serial not in devices:
            logger.error(f"设备 {self.device_serial} 未连接")
            return False

        logger.info(f"已连接设备: {self.device_serial}")
        return True

    def screenshot(self, save_path: Optional[str] = None) -> Optional[np.ndarray]:
        """
        截取屏幕并返回 OpenCV 图像
        如果指定 save_path 则保存到文件
        """
        success, output = self._run_adb(["exec-out", "screencap", "-p"])
        if not success:
            logger.error(f"截图失败: {output}")
            return None

        # 将字节流转换为 OpenCV 图像
        try:
            img_bytes = output.encode("latin-1") if isinstance(output, str) else output
            # 对于 exec-out，需要获取原始字节
            # 重新运行获取原始字节
            proc = subprocess.run(
                ["adb"] + (["-s", self.device_serial] if self.device_serial else [])
                + ["exec-out", "screencap", "-p"],
                capture_output=True,
                timeout=15,
            )
            img_array = np.frombuffer(proc.stdout, dtype=np.uint8)
            img = cv2.imdecode(img_array, cv2.IMREAD_COLOR)

            if save_path:
                cv2.imwrite(save_path, img)
                logger.info(f"截图已保存: {save_path}")

            return img
        except Exception as e:
            logger.error(f"处理截图失败: {e}")
            return None

    def tap(self, x: int, y: int):
        """点击屏幕指定坐标"""
        success, output = self._run_adb(["shell", "input", "tap", str(x), str(y)])
        if not success:
            logger.error(f"点击失败 ({x},{y}): {output}")
        return success

    def swipe(self, x1: int, y1: int, x2: int, y2: int, duration_ms: int = 300):
        """滑动屏幕"""
        success, output = self._run_adb([
            "shell", "input", "swipe",
            str(x1), str(y1), str(x2), str(y2), str(duration_ms)
        ])
        if not success:
            logger.error(f"滑动失败: {output}")
        return success

    def text_input(self, text: str):
        """输入文本 (仅支持 ASCII，中文需要 adbkeyboard)"""
        # 中文输入建议使用 adb 传送剪贴板方案
        escaped = text.replace(" ", "%s").replace("'", "'\"'\"'")
        success, output = self._run_adb([
            "shell", "input", "text", escaped
        ])
        if not success:
            logger.error(f"文本输入失败: {output}")
        return success

    def set_clipboard(self, text: str):
        """设置剪贴板内容（可用于中文输入）"""
        # 需要 API 29+ (Android 10+)，Mate60 Pro 支持
        success, _ = self._run_adb([
            "shell", "am", "broadcast",
            "-a", "org.adb.clipboard.set",
            "-e", "text", text
        ])
        return success

    def press_key(self, keycode: int):
        """模拟按键"""
        success, output = self._run_adb(["shell", "input", "keyevent", str(keycode)])
        if not success:
            logger.error(f"按键失败: {output}")
        return success

    def press_back(self):
        """按下返回键"""
        return self.press_key(4)

    def press_home(self):
        """按下 Home 键"""
        return self.press_key(3)

    def open_app(self, package_name: str, activity: Optional[str] = None):
        """打开 App"""
        if activity:
            cmd = f"am start -n {package_name}/{activity}"
        else:
            cmd = f"monkey -p {package_name} -c android.intent.category.LAUNCHER 1"
        success, output = self._run_adb(["shell", cmd])
        if not success:
            logger.error(f"打开 App 失败: {output}")
        return success

    def close_app(self, package_name: str):
        """关闭 App"""
        success, output = self._run_adb(["shell", "am", "force-stop", package_name])
        if not success:
            logger.error(f"关闭 App 失败: {output}")
        return success

    def get_foreground_package(self) -> Optional[str]:
        """获取当前前台 App 包名"""
        success, output = self._run_adb([
            "shell", "dumpsys", "window", "|", "grep", "mCurrentFocus"
        ])
        if success and output:
            # 解析如: mCurrentFocus=Window{... com.example.app/...}
            import re
            match = re.search(r'([a-zA-Z0-9.]+)/', output)
            if match:
                return match.group(1)
        return None

    def wait_for_package(self, package_name: str, timeout: float = 10.0) -> bool:
        """等待某个 App 出现在前台"""
        start = time.time()
        while time.time() - start < timeout:
            current = self.get_foreground_package()
            if current and package_name in current:
                return True
            time.sleep(0.5)
        return False

    def get_current_activity(self) -> Optional[str]:
        """获取当前 Activity"""
        success, output = self._run_adb([
            "shell", "dumpsys", "window", "|", "grep", "mCurrentFocus"
        ])
        if success and output:
            import re
            match = re.search(r'/([a-zA-Z0-9._]+)}', output)
            if match:
                return match.group(1)
        return None

    def find_image_on_screen(
        self,
        template_path: str,
        threshold: float = 0.8,
        region: Optional[Tuple[int, int, int, int]] = None,
    ) -> Optional[Tuple[int, int]]:
        """
        在屏幕截图中查找模板图片位置
        region: (x, y, w, h) 搜索区域，可提高速度和准确性
        返回匹配中心坐标 (x, y) 或 None
        """
        screenshot = self.screenshot()
        if screenshot is None:
            return None

        template = cv2.imread(template_path, cv2.IMREAD_COLOR)
        if template is None:
            logger.error(f"无法加载模板图片: {template_path}")
            return None

        # 搜索区域
        search_img = screenshot
        if region:
            x, y, w, h = region
            search_img = screenshot[y : y + h, x : x + w]

        # 模板匹配
        result = cv2.matchTemplate(search_img, template, cv2.TM_CCOEFF_NORMED)
        _, max_val, _, max_loc = cv2.minMaxLoc(result)

        if max_val < threshold:
            logger.debug(f"模板匹配失败: 最高置信度 {max_val:.3f} < {threshold}")
            return None

        # 计算中心坐标
        center_x = max_loc[0] + template.shape[1] // 2
        center_y = max_loc[1] + template.shape[0] // 2

        # 如果有 region 偏移，需要加上偏移量
        if region:
            center_x += region[0]
            center_y += region[1]

        logger.info(f"模板匹配成功: ({center_x}, {center_y}), 置信度 {max_val:.3f}")
        return (center_x, center_y)

    def click_image(
        self,
        template_path: str,
        threshold: float = 0.8,
        region: Optional[Tuple[int, int, int, int]] = None,
    ) -> bool:
        """查找并点击屏幕上的图片"""
        pos = self.find_image_on_screen(template_path, threshold, region)
        if pos:
            return self.tap(*pos)
        return False

    def wait_and_click(
        self,
        x: int,
        y: int,
        max_wait: float = 5.0,
        interval: float = 0.5,
    ) -> bool:
        """等待一定时间后点击 (用于定时抢票)"""
        start = time.time()
        while time.time() - start < max_wait:
            if self.tap(x, y):
                return True
            time.sleep(interval)
        return False

    def get_screen_size(self) -> Tuple[int, int]:
        """获取屏幕尺寸"""
        success, output = self._run_adb(["shell", "wm", "size"])
        if success:
            import re
            match = re.search(r'(\d+)x(\d+)', output)
            if match:
                return int(match.group(1)), int(match.group(2))
        return config.DEVICE_WIDTH, config.DEVICE_HEIGHT

    def unlock_screen(self):
        """唤醒并解锁屏幕（需要无锁屏密码或已解锁）"""
        self.press_key(26)  # Power 键
        time.sleep(1)
        self.swipe(630, 2000, 630, 800, 500)  # 上滑解锁
        time.sleep(1)

    def is_screen_on(self) -> bool:
        """检查屏幕是否亮起"""
        success, output = self._run_adb(["shell", "dumpsys", "power"])
        if success:
            return "mScreenOn=true" in output or "Display Power: state=ON" in output
        return False
