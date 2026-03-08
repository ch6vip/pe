import 'dart:async';

/// 防抖器（Debouncer）
///
/// 用于延迟执行频繁触发的操作（如搜索输入）
/// 避免短时间内多次网络请求
class Debouncer {
  final Duration delay;
  Timer? _timer;

  Debouncer({this.delay = const Duration(milliseconds: 300)});

  /// 执行防抖任务
  ///
  /// 如果在延迟期内有新的调用，会重置计时器
  void run(void Function() action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  /// 取消当前待执行的任务
  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  /// 释放资源
  void dispose() {
    _timer?.cancel();
    _timer = null;
  }

  /// 检查是否有待执行的任务
  bool get hasPendingTask => _timer?.isActive ?? false;
}
