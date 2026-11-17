import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_firebase/pages/account_settings_page.dart';
import 'package:flutter_firebase/pages/login_page.dart';
import 'package:material_ui/material_ui.dart' as material;

void main() {
  testWidgets('login password can be shown and hidden', (tester) async {
    await tester.pumpWidget(const material.MaterialApp(home: LoginPage()));
    final passwordField = find.byType(material.TextFormField).at(1);

    expect(_isObscured(tester, passwordField), isTrue);

    await tester.tap(find.byTooltip('Show password'));
    await tester.pump();
    expect(_isObscured(tester, passwordField), isFalse);

    await tester.tap(find.byTooltip('Hide password'));
    await tester.pump();
    expect(_isObscured(tester, passwordField), isTrue);
  });

  testWidgets('change password fields toggle visibility independently', (
    tester,
  ) async {
    await tester.pumpWidget(
      const material.MaterialApp(home: ChangePasswordPage()),
    );
    final passwordFields = [
      find.byType(material.TextFormField).at(0),
      find.byType(material.TextFormField).at(1),
      find.byType(material.TextFormField).at(2),
    ];
    const labels = ['Current Password', 'New Password', 'Confirm New Password'];

    for (var index = 0; index < labels.length; index++) {
      await tester.tap(find.byTooltip('Show ${labels[index]}'));
      await tester.pump();

      expect(_isObscured(tester, passwordFields[index]), isFalse);
      for (
        var otherIndex = index + 1;
        otherIndex < passwordFields.length;
        otherIndex++
      ) {
        expect(_isObscured(tester, passwordFields[otherIndex]), isTrue);
      }
    }
  });
}

bool _isObscured(WidgetTester tester, Finder formField) {
  final editableText = find.descendant(
    of: formField,
    matching: find.byType(material.EditableText),
  );
  return tester.widget<material.EditableText>(editableText).obscureText;
}
