// lib/app/modules/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/api_client.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  int _tab = 0;

  late final ApiClient _api = Get.find<ApiClient>();
  Future<Map<String, dynamic>>? _me;

  @override
  void initState() {
    super.initState();

    _me = _api
        .get('/me', withAuth: true)
        .then((res) => res.data as Map<String, dynamic>)
        // 2 параметртэй хэлбэр байж болно: (error, stack)
        .catchError((_, __) => <String, dynamic>{
              'user': {'displayName': 'Хэрэглэгч'},
              'households': <dynamic>[],
            });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _me,
      builder: (context, snapshot) {
        final title = _householdTitle(snapshot.data);
        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: const Color(0xFF1E1F22),
          drawer: const _SideDrawer(),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),
            centerTitle: true,
            title: Column(
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const Text(' ',
                    // subtitle space (фигма дээр жижиг subtitle байсан)
                    style: TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded),
                onPressed: () {},
              )
            ],
          ),
          body: _buildBody(context),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _tab,
            onDestinationSelected: (i) => setState(() => _tab = i),
            destinations: const [
              NavigationDestination(icon: Icon(Icons.apartment_outlined), label: 'Хотхон'),
              NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Манай гэр'),
              NavigationDestination(icon: Icon(Icons.videocam_outlined), label: 'Камер'),
              NavigationDestination(icon: Icon(Icons.person_add_alt_1_outlined), label: 'Зочин нэвтрэх'),
            ],
          ),
        );
      },
    );
  }

  String _householdTitle(dynamic data) {
    try {
      final list = (data as Map?)?['households'] as List?;
      if (list != null && list.isNotEmpty) {
        final first = list.first as Map<String, dynamic>;
        final hh = first['household'] as Map<String, dynamic>?;
        return (hh?['name'] as String?)?.trim().isNotEmpty == true
            ? hh!['name']
            : 'Миний гэр';
      }
    } catch (_) {}
    return 'Миний гэр';
  }

  Widget _buildBody(BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          sliver: SliverToBoxAdapter(
            child: _TopMetrics(),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          sliver: SliverToBoxAdapter(
            child: _WeatherRow(),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          sliver: SliverToBoxAdapter(
            child: _SectionHeader(
              title: 'Өрөний статус',
              onSeeAll: () {},
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 220,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _cameraItems.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) => _CameraCard(item: _cameraItems[i]),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          sliver: SliverToBoxAdapter(
            child: _SectionHeader(
              title: 'Хотхоны мэдээлэл',
              onSeeAll: () {},
            ),
          ),
        ),
        const SliverPadding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 24),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: [
                Expanded(child: _NewsThumb(title: 'Талбайн шинэчлэл')),
                SizedBox(width: 12),
                Expanded(child: _NewsThumb(title: 'Дэд бүтцийн засвар')),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// --------------------------
/// UI БҮРДЛҮҮД
/// --------------------------

class _TopMetrics extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: _MetricCard(
            title: 'Гадна температур',
            value: '22.3°C',
            icon: Icons.thermostat_outlined,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _MetricCard(
            title: 'Чийгшил',
            value: '93.5%',
            icon: Icons.water_drop_outlined,
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  const _MetricCard(
      {required this.title, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardBox,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Icon(icon, color: const Color(0xFFFE8C00)),
              const SizedBox(width: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeatherRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _cardBox,
      padding: const EdgeInsets.all(14),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _WeatherItem(icon: Icons.cloud_queue, label: 'Цаг агаар', value: '23°C'),
          _WeatherItem(
              icon: Icons.air_rounded, label: 'Салхины хурд', value: '9м/с'),
          _WeatherItem(
              icon: Icons.umbrella_outlined, label: 'ТуН… Магадлал', value: '40%'),
        ],
      ),
    );
  }
}

class _WeatherItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _WeatherItem(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onSeeAll;
  const _SectionHeader({required this.title, required this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const Spacer(),
        GestureDetector(
          onTap: onSeeAll,
          child: const Row(
            children: [
              Text('Бүгд', style: TextStyle(color: Colors.orange)),
              SizedBox(width: 4),
              Icon(Icons.north_east, size: 16, color: Colors.orange),
            ],
          ),
        )
      ],
    );
  }
}

class _CameraCard extends StatelessWidget {
  final _CamItem item;
  const _CameraCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      decoration: _cardBox,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // image area
          Stack(
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  item.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Container(color: Colors.black26, child: const Center(child: Icon(Icons.videocam_outlined))),
                ),
              ),
              Positioned(
                left: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.shade600,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('LIVE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                ),
              ),
              Positioned(
                right: 8,
                top: 8,
                child: _Chip(text: item.timestamp),
              ),
            ],
          ),
          // info row
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.thermostat, size: 18, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(item.temp),
                    const SizedBox(width: 12),
                    const Icon(Icons.water_drop, size: 18, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(item.humid),
                    const SizedBox(width: 12),
                    const Icon(Icons.battery_full, size: 18, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(item.battery),
                  ],
                ),
                const SizedBox(height: 8),
                Text(item.location, style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String text;
  const _Chip({required this.text});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(.55),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text, style: const TextStyle(fontSize: 11)),
    );
  }
}

class _NewsThumb extends StatelessWidget {
  final String title;
  const _NewsThumb({required this.title});
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 96,
      decoration: _cardBox,
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.network(
              'https://images.unsplash.com/photo-1460353581641-37baddab0fa2?q=80&w=800',
              fit: BoxFit.cover,
              color: Colors.black.withOpacity(.25),
              colorBlendMode: BlendMode.darken,
            ),
          ),
          Positioned(
            left: 10,
            right: 10,
            bottom: 10,
            child: Text(title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          )
        ],
      ),
    );
  }
}

const _cardBox = BoxDecoration(
  color: Color(0xFF2A2B2F),
  borderRadius: BorderRadius.all(Radius.circular(16)),
);

/// --------------------------
/// ДЕМО ӨГӨГДӨЛ
/// --------------------------

class _CamItem {
  final String title;
  final String imageUrl;
  final String temp;
  final String humid;
  final String battery;
  final String location;
  final String timestamp;
  const _CamItem({
    required this.title,
    required this.imageUrl,
    required this.temp,
    required this.humid,
    required this.battery,
    required this.location,
    required this.timestamp,
  });
}

final _cameraItems = <_CamItem>[
  const _CamItem(
    title: 'ТОМ ӨРӨӨ',
    imageUrl:
        'https://images.unsplash.com/photo-1519710164239-da123dc03ef4?q=80&w=1200',
    temp: '22.3°C',
    humid: '93.5%',
    battery: '93%',
    location: 'Том өрөө',
    timestamp: '2025.09.11 23:00',
  ),
  const _CamItem(
    title: 'ГАЛ ТОГОО',
    imageUrl:
        'https://images.unsplash.com/photo-1505692794403-34d4982f88aa?q=80&w=1200',
    temp: '22.2°C',
    humid: '50%',
    battery: '98%',
    location: 'Гал тогоо',
    timestamp: '2025.09.11 23:00',
  ),
];
 
/// --------------------------
/// ХАЖУУ ЦЭС (Drawer)
/// --------------------------
class _SideDrawer extends StatelessWidget {
  const _SideDrawer();

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyMedium;
    return Drawer(
      backgroundColor: const Color(0xFF1E1F22),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(0),
          children: [
            const ListTile(
              leading: CircleAvatar(child: Icon(Icons.person)),
              title: Text('Миний мэдээлэл'),
              subtitle: Text('Өрөө/тоот'),
            ),
            const Divider(height: 1),
            ListTile(leading: const Icon(Icons.account_circle_outlined), title: Text('Миний мэдээлэл', style: textStyle)),
            ListTile(leading: const Icon(Icons.home_work_outlined), title: Text('Миний хөрөнгө', style: textStyle)),
            ListTile(leading: const Icon(Icons.share_outlined), title: Text('Социал холбоо', style: textStyle)),
            ListTile(leading: const Icon(Icons.qr_code_scanner_outlined), title: Text('Хэтэвч цэнэглэх', style: textStyle)),
            ListTile(leading: const Icon(Icons.credit_card_outlined), title: Text('Карт холбох', style: textStyle)),
            ListTile(leading: const Icon(Icons.receipt_long_outlined), title: Text('И-баримт холбох', style: textStyle)),
            ListTile(leading: const Icon(Icons.support_agent_outlined), title: Text('Утасны жагсаалт', style: textStyle)),
            ListTile(leading: const Icon(Icons.forum_outlined), title: Text('Санал хүсэлт', style: textStyle)),
            ListTile(leading: const Icon(Icons.rule_folder_outlined), title: Text('Үйлчилгээний нөхцөл', style: textStyle)),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Системээс гарах'),
              onTap: () => Get.back(), // эндээс AuthController.logout дуудах боломжтой
            ),
          ],
        ),
      ),
    );
  }
}
