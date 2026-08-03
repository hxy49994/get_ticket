# 大麦抢票助手 - 鸿蒙原生应用

## 项目结构

```
get_ticket/
├── entry/
│   ├── src/main/
│   │   ├── ets/
│   │   │   ├── pages/
│   │   │   │   ├── EntryPage.ets           # 主页面（倒计时 + 配置）
│   │   │   │   └── FloatWindowAbility.ets  # 悬浮窗页面
│   │   │   ├── entryability/
│   │   │   │   └── EntryAbility.ets        # 入口 Ability
│   │   │   ├── services/
│   │   │   │   └── TicketServiceAbility.ets # 后台抢票服务
│   │   │   └── extensions/
│   │   │       └── TicketWorkExtension.ets  # WorkScheduler 扩展
│   │   ├── resources/
│   │   │   └── base/element/
│   │   │       ├── string.json             # 字符串资源
│   │   │       └── color.json              # 颜色资源
│   │   └── module.json5                    # 模块配置
│   └── build-profile.json5
├── build-profile.json5
├── hvigorfile.ts
└── README_HARMONY.md
```

## 使用说明

### 1. 开发环境

- **IDE**: DevEco Studio 或 Aircode（鸿蒙原生 IDE）
- **SDK**: HarmonyOS 4.0+
- **OpenHarmony API**: API 10+

### 2. 导入项目

1. 打开 DevEco Studio / Aircode
2. 选择 `File` → `Open` → 选择 `get_ticket` 目录
3. 等待 Gradle/Hvigor 同步完成

### 3. 配置权限

在 `module.json5` 中已配置以下权限：

| 权限 | 用途 |
|------|------|
| `ohos.permission.INTERNET` | 访问网络 |
| `ohos.permission.SYSTEM_ALERT_WINDOW` | 悬浮窗显示 |

### 4. 运行

1. 连接华为手机（开启 USB 调试）
2. 点击 `Run` 或 `Shift+F10`
3. 安装后打开应用

### 5. 核心功能

#### 倒计时页面
- 设置抢票时间（时/分/秒）
- 显示倒计时
- 开始/停止控制

#### 悬浮窗
- 后台显示倒计时
- 不占用前台应用
- 可快速关闭

#### 后台服务
- 使用 WorkScheduler 调度定时任务
- 到达时间自动执行抢票流程
- 跳转到大麦 App → 提交订单 → 跳转支付宝

## 技术要点

### 1. 后台任务调度

```typescript
// 使用 WorkScheduler 进行周期性调度
workScheduler.schedulePeriodicWork(workRequest, 3600000)
```

### 2. 悬浮窗权限

```json
{
  "requestPermissions": [
    {
      "name": "ohos.permission.SYSTEM_ALERT_WINDOW",
      "usedScene": {
        "when": "inuse"
      }
    }
  ]
}
```

### 3. 后台服务

```typescript
// 使用 UIAbility 作为后台服务
@Entry
@Component
struct TicketServiceAbility {
  onStart(want: Want) {
    // 执行抢票逻辑
  }
}
```

## 注意事项

1. **鸿蒙系统限制**: 鸿蒙 6.1 对后台运行和模拟点击有限制，可能需要用户手动开启相关权限
2. **无障碍服务**: 如需模拟点击，可能需要申请无障碍权限（鸿蒙可能限制）
3. **应用保活**: 后台任务可能被系统回收，建议使用前台服务（悬浮窗可作为保活手段）
4. **测试**: 不同鸿蒙版本可能有不同的权限策略，建议在目标设备上充分测试

## 构建命令

```bash
# 清理构建
hvigorw clean

# 构建 Debug 版本
hvigorw assembleDebug

# 构建 Release 版本
hvigorw assembleRelease

# 运行到设备
hvigorw install
```

## 后续优化

1. **图像识别**: 集成 OpenCV 进行屏幕内容识别
2. **更精准的定时**: 使用系统级定时器
3. **多场次支持**: 支持同时监控多个场次
4. **通知提醒**: 抢票成功/失败时发送系统通知
