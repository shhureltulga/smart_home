import 'package:flutter/material.dart';

import '../../theme.dart';
import '../dashboard/dashboard_screen.dart';
import 'app_drawer.dart';
import 'package:smart_home/app/modules/shell/root_scaffold.dart';


class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final _rootKey = GlobalKey<ScaffoldState>();
  int _index = 0;

  // Табууд – body-г дотор нь өөр Scaffold ашиглахгүй байвал drawer автоматаар ажиллана.
  final List<Widget> _tabs = const [
    DashboardScreen(),                 // Нүүр
    // _Stub(title: 'Эрүүл мэнд хяналт'),
    _Stub(title: 'Зардлын хяналт'),
    // _Stub(title: 'Хүүхдийн хяналт'),
    _Stub(title: 'Профайл'),
  ];

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppTokens>();

    return RootScaffold(
      scaffoldKey: _rootKey,
      child: Scaffold(
        key: _rootKey,
        drawer: const AppDrawer(),
        body: IndexedStack(index: _index, children: _tabs),
        bottomNavigationBar: NavigationBarTheme(
          data: NavigationBarThemeData(
            backgroundColor: tokens?.surfaceCard,
            indicatorColor:
                (tokens?.accent ?? Theme.of(context).colorScheme.secondary)
                    .withOpacity(.15),
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              final sel = states.contains(WidgetState.selected);
              return TextStyle(
                fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
              );
            }),
          ),
          child: NavigationBar(
            selectedIndex: _index,
            height: 64,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: 'Гэр',
              ),
              // NavigationDestination(
              //   icon: Icon(Icons.favorite_border),
              //   selectedIcon: Icon(Icons.favorite),
              //   label: 'Бие',
              // ),
              NavigationDestination(
                icon: Icon(Icons.payments_outlined),
                selectedIcon: Icon(Icons.payments),
                label: 'Зардал',
              ),
              // NavigationDestination(
              //   icon: Icon(Icons.child_care_outlined),
              //   selectedIcon: Icon(Icons.child_care),
              //   label: 'Хүүхэд',
              // ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Профайл',
              ),
            ],
            onDestinationSelected: (i) => setState(() => _index = i),
          ),
        ),
      ),
    );
  }
}

class _Stub extends StatelessWidget {
  final String title;
  const _Stub({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // ⚠️ ЭНЭ ТОВЧ нь эцэг Scaffold-ийн drawer-ыг нээнэ
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => RootScaffold.openDrawer(context),
        ),
        title: Text(title),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_outlined),
          ),
        ],
      ),
      body: Center(child: Text('$title дэлгэц (WIP)')),
    );
  }
}
