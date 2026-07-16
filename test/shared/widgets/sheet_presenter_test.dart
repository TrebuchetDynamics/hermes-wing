import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wing/shared/widgets/sheet_presenter.dart';

void main() {
  testWidgets('ActionSheet renders title and action rows', (tester) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showSheet(
                context,
                ActionSheet(
                  'Test title',
                  rows: [
                    SheetActionRow(
                      Icons.star,
                      'Action 1',
                      onTap: (_) {
                        tapped = true;
                      },
                    ),
                    SheetActionRow(Icons.favorite, 'Action 2', onTap: (_) {}),
                  ],
                ),
              ),
              child: const Text('Show sheet'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Show sheet'));
    await tester.pumpAndSettle();

    expect(find.text('Test title'), findsOneWidget);
    expect(find.text('Action 1'), findsOneWidget);
    expect(find.text('Action 2'), findsOneWidget);

    await tester.tap(find.text('Action 1'));
    await tester.pumpAndSettle();

    expect(tapped, isTrue);
  });

  testWidgets('ActionSheet row tap receives sheet context', (tester) async {
    BuildContext? capturedContext;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showSheet(
                context,
                ActionSheet(
                  'Test',
                  rows: [
                    SheetActionRow(
                      Icons.check,
                      'Pop me',
                      onTap: (sheetContext) {
                        capturedContext = sheetContext;
                        Navigator.of(sheetContext).pop();
                      },
                    ),
                  ],
                ),
              ),
              child: const Text('Show sheet'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Show sheet'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pop me'));
    await tester.pumpAndSettle();

    expect(capturedContext, isNotNull);
    // Sheet should be dismissed after pop
    expect(find.text('Pop me'), findsNothing);
  });

  testWidgets('InfoActionSheet renders info rows, divider, and action rows', (
    tester,
  ) async {
    var actionTapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showSheet(
                context,
                InfoActionSheet(
                  'Info title',
                  infoRows: [
                    SheetInfoRow(Icons.person, 'Name', 'Alice'),
                    SheetInfoRow(Icons.tag, 'ID', 'abc123'),
                  ],
                  actions: [
                    SheetActionRow(
                      Icons.settings,
                      'Settings',
                      onTap: (_) {
                        actionTapped = true;
                      },
                    ),
                  ],
                ),
              ),
              child: const Text('Show sheet'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Show sheet'));
    await tester.pumpAndSettle();

    expect(find.text('Info title'), findsOneWidget);
    expect(find.text('Name'), findsOneWidget);
    expect(find.text('Alice'), findsOneWidget);
    expect(find.text('ID'), findsOneWidget);
    expect(find.text('abc123'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(actionTapped, isTrue);
  });

  testWidgets('long action sheet uses DraggableScrollableSheet', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showSheet(
                context,
                ActionSheet(
                  'Many actions',
                  rows: [
                    for (var i = 0; i < 8; i++)
                      SheetActionRow(Icons.star, 'Action $i', onTap: (_) {}),
                  ],
                ),
              ),
              child: const Text('Show sheet'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Show sheet'));
    await tester.pumpAndSettle();

    // Scroll down to verify all rows are accessible
    await tester.drag(
      find.byType(DraggableScrollableSheet),
      const Offset(0, -300),
    );
    await tester.pumpAndSettle();

    expect(find.text('Action 7'), findsOneWidget);
  });
}
