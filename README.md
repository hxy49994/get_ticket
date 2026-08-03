# 大麦抢票自动化工具

通过 ADB (USB 连接) 控制华为 Mate60 Pro，模拟人工操作大麦 App 抢票。

## 风险提示

**使用前请务必了解以下风险：**
- 违反大麦用户协议，账号可能被封禁
- 大麦有反自动化检测机制
- 仅供技术学习研究

## 环境要求

| 项目 | 要求 |
|------|------|
| 电脑 | MacBook (macOS) 或 Windows |
| 手机 | 华为 Mate60 Pro (或其他 Android 手机) |
| 连接 | USB 数据线 |
| 手机设置 | 开启「开发者选项」→「USB 调试」 |
| 软件 | Python 3.9+、ADB |

## 安装

```bash
# 1. 安装 ADB (如果还没有)
brew install android-platform-tools    # macOS
# 或者从 https://developer.android.com/studio/releases/platform-tools 下载

# 2. 安装 Python 依赖
pip install -r requirements.txt

# 3. 连接手机并确认
adb devices
# 应该看到类似:
# 1234567890abcdef     device
```

## 使用步骤

### 第一步：配置抢票信息

编辑 `config.py`，修改以下配置：

```python
# 抢票时间
TICKET_TIME = {"hour": 10, "minute": 0, "second": 0}
```

### 第二步：校准坐标

大麦 App 每次更新 UI 都可能变化，需要校准按钮坐标：

```bash
python main.py
# 进入菜单选择 [4] 校准坐标
# 打开大麦 App 并进入目标页面
# 程序会每隔 2 秒截图，保存到当前目录
```

截图后查看图片，用图片查看器或 PS 找到关键按钮的坐标 (x, y)，更新到 `config.py` 中。

**关键按钮需要校准：**
- `TAB_MY` - 底部导航「我的」按钮
- `BTN_MY_TICKET` - 「我的门票」按钮
- `BTN_BUY_NOW` - 「立即购买」按钮
- `BTN_SUBMIT` - 「提交订单」按钮

### 第三步：开始抢票

```bash
# 交互模式
python main.py

# 自动模式 (直接运行抢票)
python main.py --auto
```

交互模式下：
1. 选择 [1] 连接设备
2. 选择 [5] 开始抢票
3. 程序会等待到抢票时间自动执行

## 核心流程

```
大麦 App → 我的 → 我的门票 → 选择场次
    → 等待开抢 → 点击购买 → 选择场次/价格
    → 提交订单 → 跳转支付宝
```

## 常见问题

### USB 连接后 ADB 找不到设备
- 确认华为手机开启了「USB 调试」
- 换用原装数据线
- 在「开发者选项」中关闭「监控 ADB 安装应用」

### 坐标不准
大麦版本更新后 UI 位置可能变化，需要重新校准坐标。

### 抢票失败
- 网络延迟可能导致点击时间不准
- 大麦可能有抢票验证码或滑块验证
- 多次失败账号可能被风控
