import 'package:flutter/material.dart';
import 'package:smenergy/pages/History_page.dart';
import 'package:smenergy/pages/alert_page.dart';
import 'package:smenergy/pages/dashboard_page.dart';
import 'package:smenergy/pages/profile_page.dart';
import 'package:smenergy/services/energy_data_service.dart';

class GamificationPage extends StatefulWidget {
  const GamificationPage({super.key});

  @override
  State<GamificationPage> createState() => _GamificationPageState();
}

class _GamificationPageState extends State<GamificationPage> {
  int _selectedIndex = 3;
  final EnergyDataService _energyDataService = EnergyDataService();
  bool _isLoading = true;
  GamificationProfile _profile = const GamificationProfile.empty();

  @override
  void initState() {
    super.initState();
    _loadGamificationProfile();
  }

  Future<void> _loadGamificationProfile() async {
    try {
      final profile = await _energyDataService.fetchGamificationProfile();
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Gamificação',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: _isLoading
            ? const Padding(
                padding: EdgeInsets.only(top: 40),
                child: Center(child: CircularProgressIndicator()),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  _buildSummaryCard(),
                  const SizedBox(height: 20),
                  _buildLevelTimeline(),
                  const SizedBox(height: 24),
                ],
              ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildSummaryCard() {
    final nextLevel = _profile.nextLevel;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FBFF),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFDCEBFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pontos acumulados',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6C86A2),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${_profile.points}',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF2F3443),
                      ),
                    ),
                  ],
                ),
              ),
              _buildAssetIcon(
                _profile.level.assetPath,
                fallback: Icons.workspace_premium_rounded,
                size: 58,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                _profile.level.label,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1D7EF8),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFFDCEBFF)),
                ),
                child: const Text(
                  'Nível atual',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1D7EF8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _profile.helperText,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF6C86A2),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFDCEBFF)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Text(
                      'Progresso',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2F3443),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${_profile.progressPercent}%',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1D7EF8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildProgressPill(_profile.progressLabel),
                    const SizedBox(width: 12),
                    Expanded(child: _buildProgressBar(_profile.progress)),
                  ],
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    nextLevel == null
                        ? 'Nível máximo alcançado'
                        : 'Próximo nível: ${nextLevel.minPoints}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6C86A2),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelTimeline() {
    final levels = GamificationLevel.values;
    const double cardHeight = 110;
    const double cardSpacing = 16;
    const double dotColumnWidth = 40;
    const double dotSize = 22;
    const double lineWidth = 3;
    const double lineInset = (cardHeight / 2) - (dotSize / 2);
    const double lineLeft = (dotColumnWidth / 2) - (lineWidth / 2);
    final totalHeight =
        (cardHeight * levels.length) + (cardSpacing * (levels.length - 1));

    return SizedBox(
      height: totalHeight,
      child: Stack(
        children: [
          Positioned(
            left: lineLeft,
            top: lineInset,
            bottom: lineInset,
            child: Container(
              width: lineWidth,
              decoration: BoxDecoration(
                color: const Color(0xFFD8DCE3),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          Column(
            children: List.generate(levels.length, (index) {
              final level = levels[index];
              final isCurrent = _profile.level == level;
              final isUnlocked = _profile.points >= level.minPoints;

              return Padding(
                padding: EdgeInsets.only(
                  bottom: index == levels.length - 1 ? 0 : cardSpacing,
                ),
                child: _buildLevelRow(
                  dotColumnWidth: dotColumnWidth,
                  cardHeight: cardHeight,
                  level: level,
                  isCurrent: isCurrent,
                  isUnlocked: isUnlocked,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelRow({
    required double dotColumnWidth,
    required double cardHeight,
    required GamificationLevel level,
    required bool isCurrent,
    required bool isUnlocked,
  }) {
    final backgroundColor = isCurrent
        ? const Color(0xFFE6F2FF)
        : isUnlocked
        ? const Color(0xFFF7FBFF)
        : Colors.white;
    final borderColor = isCurrent || isUnlocked
        ? const Color(0xFF3DA5FA)
        : const Color(0xFFD8DCE3);
    final statusLabel = isCurrent
        ? 'Atual'
        : isUnlocked
        ? 'Desbloqueado'
        : 'Bloqueado';
    final statusColor = isCurrent
        ? const Color(0xFF1D7EF8)
        : isUnlocked
        ? const Color(0xFF3DA5FA)
        : const Color(0xFF8C9BB5);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: dotColumnWidth,
          child: Align(
            alignment: Alignment.center,
            child: _buildTimelineDot(
              isCurrent: isCurrent,
              isUnlocked: isUnlocked,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: cardHeight,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: borderColor, width: 1.5),
            ),
            child: Row(
              children: [
                _buildAssetIcon(
                  level.assetPath,
                  fallback: _fallbackIcon(level),
                  size: level == GamificationLevel.pulse ? 64 : 56,
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        level.label,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${level.minPoints} Pontos',
                        style: TextStyle(
                          color: isUnlocked
                              ? const Color(0xFF3DA5FA)
                              : const Color(0xFF8C9BB5),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: statusColor.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Text(
                          statusLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineDot({
    required bool isCurrent,
    required bool isUnlocked,
  }) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: const Color(0xFF3DA5FA), width: 2),
      ),
      child: isUnlocked
          ? Center(
              child: Container(
                width: isCurrent ? 10 : 8,
                height: isCurrent ? 10 : 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCurrent
                      ? const Color(0xFF3DA5FA)
                      : const Color(0xFFAED5FF),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildAssetIcon(
    String asset, {
    required IconData fallback,
    double size = 54,
  }) {
    return Image.asset(
      asset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Icon(fallback, color: const Color(0xFF3DA5FA), size: size);
      },
    );
  }

  IconData _fallbackIcon(GamificationLevel level) {
    switch (level) {
      case GamificationLevel.pulse:
        return Icons.radio_button_checked;
      case GamificationLevel.volt:
        return Icons.bolt_rounded;
      case GamificationLevel.zeus:
        return Icons.workspace_premium_rounded;
    }
  }

  Widget _buildProgressPill(String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF1D7EF8),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        value,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildProgressBar(double value) {
    final safeValue = value.clamp(0.0, 1.0);

    return Container(
      height: 14,
      decoration: BoxDecoration(
        color: const Color(0xFFE7F1FE),
        borderRadius: BorderRadius.circular(999),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              Container(
                width: constraints.maxWidth * safeValue,
                decoration: BoxDecoration(
                  color: const Color(0xFF1D7EF8),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F0FE),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: BottomNavigationBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.black54,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const DashboardPage()),
            );
            return;
          }
          if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HistoryPage()),
            );
            return;
          }
          if (index == 2) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const AlertPage()),
            );
            return;
          }
          if (index == 3) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const ProfilePage()),
            );
            return;
          }
          setState(() => _selectedIndex = index);
        },
        items: [
          _navItem(Icons.grid_view_rounded, 'Dashboard', 0),
          _navItem(Icons.bar_chart_rounded, 'Histórico', 1),
          _navItem(Icons.warning_amber_rounded, 'Alertas', 2),
          _navItem(Icons.person_outline, 'Perfil', 3),
        ],
      ),
    );
  }

  BottomNavigationBarItem _navItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    return BottomNavigationBarItem(
      icon: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF3DA5FA) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(icon, color: isSelected ? Colors.white : Colors.black),
      ),
      label: label,
    );
  }
}
