import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/widgets/loading_state.dart';
import 'package:flutter_application_1/widgets/empty_state.dart';
import 'package:flutter_application_1/widgets/error_state.dart';
import 'package:flutter_application_1/widgets/app_button.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LoadingState', () {
    testWidgets('renders without error', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: LoadingState()),
      ));

      expect(find.byType(LoadingState), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('displays message when provided', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: LoadingState(message: 'Loading data...')),
      ));

      expect(find.text('Loading data...'), findsOneWidget);
    });

    testWidgets('compact mode hides message', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: LoadingState(
            message: 'Loading...',
            compact: true,
          ),
        ),
      ));

      expect(find.text('Loading...'), findsNothing);
    });
  });

  group('LoadingOverlay', () {
    testWidgets('shows overlay when loading', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: LoadingOverlay(
            isLoading: true,
            child: Text('Content'),
          ),
        ),
      ));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Content'), findsOneWidget);
    });

    testWidgets('hides overlay when not loading', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: LoadingOverlay(
            isLoading: false,
            child: Text('Content'),
          ),
        ),
      ));

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Content'), findsOneWidget);
    });
  });

  group('ShimmerLoadingItem', () {
    testWidgets('renders without error', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: ShimmerLoadingItem()),
      ));

      expect(find.byType(ShimmerLoadingItem), findsOneWidget);
    });
  });

  group('EmptyState', () {
    testWidgets('renders with icon and title', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: EmptyState(
            icon: Icons.inbox,
            title: 'No items',
          ),
        ),
      ));

      expect(find.byIcon(Icons.inbox), findsOneWidget);
      expect(find.text('No items'), findsOneWidget);
    });

    testWidgets('displays description when provided', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: EmptyState(
            icon: Icons.inbox,
            title: 'No items',
            description: 'Add some items to get started.',
          ),
        ),
      ));

      expect(find.text('Add some items to get started.'), findsOneWidget);
    });

    testWidgets('displays action button when provided', (WidgetTester tester) async {
      var actionCalled = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: EmptyState(
            icon: Icons.inbox,
            title: 'No items',
            actionLabel: 'Add Item',
            onAction: () => actionCalled = true,
          ),
        ),
      ));

      expect(find.text('Add Item'), findsOneWidget);
      await tester.tap(find.text('Add Item'));
      expect(actionCalled, true);
    });

    testWidgets('quests factory creates correct empty state', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: EmptyState.quests()),
      ));

      expect(find.text('Keine Quests verfügbar'), findsOneWidget);
    });

    testWidgets('rewards factory creates correct empty state', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: EmptyState.rewards()),
      ));

      expect(find.text('Keine Belohnungen verfügbar'), findsOneWidget);
    });

    testWidgets('approvals factory creates correct empty state', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: EmptyState.approvals()),
      ));

      expect(find.text('Keine ausstehenden Genehmigungen'), findsOneWidget);
    });
  });

  group('ErrorState', () {
    testWidgets('renders with message', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: ErrorState(message: 'Something went wrong'),
        ),
      ));

      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('displays details when provided', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: ErrorState(
            message: 'Error',
            details: 'Please try again later.',
          ),
        ),
      ));

      expect(find.text('Please try again later.'), findsOneWidget);
    });

    testWidgets('displays retry button when provided', (WidgetTester tester) async {
      var retryCalled = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ErrorState(
            message: 'Error',
            onRetry: () => retryCalled = true,
          ),
        ),
      ));

      expect(find.text('Erneut versuchen'), findsOneWidget);
      await tester.tap(find.text('Erneut versuchen'));
      expect(retryCalled, true);
    });

    testWidgets('network factory creates correct error state', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: ErrorState.network()),
      ));

      expect(find.text('Keine Internetverbindung'), findsOneWidget);
      expect(find.byIcon(Icons.wifi_off), findsOneWidget);
    });

    testWidgets('server factory creates correct error state', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: ErrorState.server()),
      ));

      expect(find.text('Server nicht erreichbar'), findsOneWidget);
      expect(find.byIcon(Icons.cloud_off), findsOneWidget);
    });
  });

  group('InlineError', () {
    testWidgets('renders with message', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: InlineError(message: 'Invalid input'),
        ),
      ));

      expect(find.text('Invalid input'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });
  });

  group('AppButton', () {
    testWidgets('primary button renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AppButton.primary(
            label: 'Click me',
            onPressed: () {},
          ),
        ),
      ));

      expect(find.text('Click me'), findsOneWidget);
    });

    testWidgets('secondary button renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AppButton.secondary(
            label: 'Secondary',
            onPressed: () {},
          ),
        ),
      ));

      expect(find.text('Secondary'), findsOneWidget);
    });

    testWidgets('text button renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AppButton.text(
            label: 'Text Button',
            onPressed: () {},
          ),
        ),
      ));

      expect(find.text('Text Button'), findsOneWidget);
    });

    testWidgets('destructive button renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AppButton.destructive(
            label: 'Delete',
            onPressed: () {},
          ),
        ),
      ));

      expect(find.text('Delete'), findsOneWidget);
    });

    testWidgets('calls onPressed when tapped', (WidgetTester tester) async {
      var pressed = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AppButton(
            label: 'Press me',
            onPressed: () => pressed = true,
          ),
        ),
      ));

      await tester.tap(find.text('Press me'));
      await tester.pump();

      expect(pressed, true);
    });

    testWidgets('shows loading indicator when loading', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AppButton(
            label: 'Loading',
            isLoading: true,
            onPressed: () {},
          ),
        ),
      ));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('displays icon when provided', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AppButton(
            label: 'Add',
            icon: Icons.add,
            onPressed: () {},
          ),
        ),
      ));

      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('does not call onPressed when disabled', (WidgetTester tester) async {
      var pressed = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AppButton(
            label: 'Disabled',
            onPressed: null,
          ),
        ),
      ));

      await tester.tap(find.text('Disabled'));
      await tester.pump();

      expect(pressed, false);
    });
  });

  group('AppIconButton', () {
    testWidgets('renders with icon', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AppIconButton(
            icon: Icons.settings,
            onPressed: () {},
          ),
        ),
      ));

      expect(find.byIcon(Icons.settings), findsOneWidget);
    });

    testWidgets('calls onPressed when tapped', (WidgetTester tester) async {
      var pressed = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AppIconButton(
            icon: Icons.settings,
            onPressed: () => pressed = true,
          ),
        ),
      ));

      await tester.tap(find.byIcon(Icons.settings));
      await tester.pump();

      expect(pressed, true);
    });

    testWidgets('shows tooltip when provided', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AppIconButton(
            icon: Icons.settings,
            tooltip: 'Settings',
            onPressed: () {},
          ),
        ),
      ));

      expect(find.byType(Tooltip), findsOneWidget);
    });
  });
}
