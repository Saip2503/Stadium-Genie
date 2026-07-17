import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stadium_genie/models/message_model.dart';
import 'package:stadium_genie/widgets/chat_bubble.dart';

void main() {
  testWidgets('ChatBubble user layout verification', (
    WidgetTester tester,
  ) async {
    final userMsg = MessageModel(
      id: "1",
      content: "Hello AI",
      role: MessageRole.user,
      timestamp: DateTime.now(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ChatBubble(message: userMsg, isDark: false)),
      ),
    );

    // Let the entry slide animation finish
    await tester.pump(const Duration(milliseconds: 300));

    // Verify user bubble aligns to right and displays text
    expect(find.text("Hello AI"), findsOneWidget);
    expect(find.text("You"), findsOneWidget);
    expect(find.text("StadiumGenie AI"), findsNothing);
  });

  testWidgets('ChatBubble assistant layout verification', (
    WidgetTester tester,
  ) async {
    final assistantMsg = MessageModel(
      id: "2",
      content: "How can I help you?",
      role: MessageRole.assistant,
      timestamp: DateTime.now(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ChatBubble(message: assistantMsg, isDark: false)),
      ),
    );

    // Let the entry slide animation finish
    await tester.pump(const Duration(milliseconds: 300));

    // Verify AI bubble aligns to left, shows correct labels
    expect(find.text("How can I help you?"), findsOneWidget);
    expect(find.text("StadiumGenie AI"), findsOneWidget);
    expect(find.text("You"), findsNothing);
  });
}
