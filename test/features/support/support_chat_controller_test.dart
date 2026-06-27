import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shipnow/core/services/support_ai_service.dart';
import 'package:shipnow/features/support/support_chat_controller.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('humanGreeted flips true after first user message', () async {
    final prefs = await SharedPreferences.getInstance();
    final ctrl = SupportChatController(userId: 'demo', prefs: prefs, ai: SupportAiService.instance);
    expect(ctrl.state.humanGreeted, isFalse);
    await ctrl.sendUser('hello');
    expect(ctrl.state.humanGreeted, isTrue);
  });

  test('humanGreeted only fires once — not on subsequent messages', () async {
    final prefs = await SharedPreferences.getInstance();
    final ctrl = SupportChatController(userId: 'demo', prefs: prefs, ai: SupportAiService.instance);
    await ctrl.sendUser('msg 1');
    final sysCount1 = ctrl.state.messages.where((m) => m.role == 'system').length;
    await ctrl.sendUser('msg 2');
    final sysCount2 = ctrl.state.messages.where((m) => m.role == 'system').length;
    expect(sysCount2, equals(sysCount1),
        reason: 'human-respond system message must only be sent once');
  });

  test('agent reply sets hasUnreadAgentReply', () async {
    final prefs = await SharedPreferences.getInstance();
    final ctrl = SupportChatController(userId: 'demo', prefs: prefs, ai: SupportAiService.instance);
    await ctrl.sendAgent('Hi from support');
    expect(ctrl.state.hasUnreadAgentReply, isTrue);
    ctrl.markRead();
    expect(ctrl.state.hasUnreadAgentReply, isFalse);
  });

  test('messages persist across controller re-creation', () async {
    final prefs = await SharedPreferences.getInstance();
    final c1 = SupportChatController(userId: 'demo', prefs: prefs, ai: SupportAiService.instance);
    await c1.sendUser('persisted message');
    // Recreate controller with same prefs.
    final c2 = SupportChatController(userId: 'demo', prefs: prefs, ai: SupportAiService.instance);
    expect(c2.state.messages.any((m) => m.text == 'persisted message'), isTrue);
    expect(c2.state.humanGreeted, isTrue);
  });
}