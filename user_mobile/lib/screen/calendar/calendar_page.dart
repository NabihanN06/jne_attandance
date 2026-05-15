import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/app_provider.dart';
import '../../models/app_models.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _focusedDay  = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Color _categoryColor(String cat) {
    switch (cat) {
      case 'meeting':  return const Color(0xFF3B9EE8);
      case 'training': return const Color(0xFF8B5CF6);
      case 'deadline': return const Color(0xFFF43F5E);
      case 'social':   return const Color(0xFFF59E0B);
      default:         return const Color(0xFF10B981);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isDark   = provider.isDarkMode;
    final user     = provider.currentUser;

    final events = provider.events.where((e) {
      final matchDept = e.departments?.contains(user?.department) ?? false;
      final matchUser = e.attendees.contains(user?.uid ?? '');
      return matchDept || matchUser;
    }).toList();

    // Palette
    final headerBg   = isDark ? const Color(0xFF0D1829) : const Color(0xFF0F172A);
    final bg         = isDark ? const Color(0xFF0B1120) : const Color(0xFFF8FAFC);
    final cardBg     = isDark ? const Color(0xFF131D2E) : Colors.white;
    final titleColor = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final mutedColor = isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);
    final shadowColor= isDark ? Colors.black.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.04);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: headerBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'SMART CALENDAR',
          style: GoogleFonts.outfit(
            color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 2,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // ── CALENDAR HEADER ──
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            decoration: BoxDecoration(
              color: headerBg,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(36),
                bottomRight: Radius.circular(36),
              ),
            ),
            child: Column(
              children: [
                _buildMonthNav(),
                const SizedBox(height: 16),
                _buildWeekHeader(),
                const SizedBox(height: 8),
                _buildGrid(events),
              ],
            ),
          ),

          // ── EVENT LIST ──
          Expanded(child: _buildEventSection(events, cardBg, titleColor, mutedColor, shadowColor, bg)),
        ],
      ),
    );
  }

  Widget _buildMonthNav() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _navBtn(Icons.chevron_left_rounded, () {
          setState(() => _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1));
        }),
        Column(
          children: [
            Text(
              DateFormat('MMMM', 'id').format(_focusedDay).toUpperCase(),
              style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1),
            ),
            Text(
              _focusedDay.year.toString(),
              style: GoogleFonts.outfit(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        _navBtn(Icons.chevron_right_rounded, () {
          setState(() => _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1));
        }),
      ],
    );
  }

  Widget _navBtn(IconData icon, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 40, height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: Colors.white70, size: 24),
    ),
  );

  Widget _buildWeekHeader() {
    const days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: days.map((d) => SizedBox(
        width: 36,
        child: Text(
          d,
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w700),
        ),
      )).toList(),
    );
  }

  Widget _buildGrid(List<CalendarEvent> events) {
    final daysInMonth   = DateTime(_focusedDay.year, _focusedDay.month + 1, 0).day;
    final firstOffset   = DateTime(_focusedDay.year, _focusedDay.month, 1).weekday - 1;
    final totalCells    = daysInMonth + firstOffset;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 6,
        crossAxisSpacing: 4,
        childAspectRatio: 1,
      ),
      itemCount: totalCells,
      itemBuilder: (context, index) {
        if (index < firstOffset) return const SizedBox();

        final day      = index - firstOffset + 1;
        final date     = DateTime(_focusedDay.year, _focusedDay.month, day);
        final isSelected = _isSameDay(date, _selectedDay);
        final isToday    = _isSameDay(date, DateTime.now());
        final dayEvents  = events.where((e) => _isSameDay(e.startDate, date)).toList();
        final hasEvents  = dayEvents.isNotEmpty;

        return GestureDetector(
          onTap: () => setState(() => _selectedDay = date),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFFE31E24)
                  : isToday
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: isToday && !isSelected
                  ? Border.all(color: const Color(0xFFE31E24).withValues(alpha: 0.6), width: 1.5)
                  : null,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  day.toString(),
                  style: GoogleFonts.outfit(
                    color: isSelected
                        ? Colors.white
                        : isToday
                            ? Colors.white
                            : Colors.white70,
                    fontSize: 13,
                    fontWeight: isSelected || isToday ? FontWeight.w900 : FontWeight.w500,
                  ),
                ),
                if (hasEvents && !isSelected)
                  Positioned(
                    bottom: 4,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: dayEvents.take(3).map((e) => Container(
                        width: 4, height: 4,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(
                          color: _categoryColor(e.category),
                          shape: BoxShape.circle,
                        ),
                      )).toList(),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEventSection(
    List<CalendarEvent> events,
    Color cardBg,
    Color titleColor,
    Color mutedColor,
    Color shadowColor,
    Color bg,
  ) {
    final dayEvents = events.where((e) => _isSameDay(e.startDate, _selectedDay)).toList();
    final isToday   = _isSameDay(_selectedDay, DateTime.now());

    return Column(
      children: [
        // ── Day header ──
        Container(
          color: bg,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('EEEE', 'id').format(_selectedDay),
                      style: GoogleFonts.outfit(color: mutedColor, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                    ),
                    Text(
                      DateFormat('d MMMM yyyy', 'id').format(_selectedDay),
                      style: GoogleFonts.outfit(color: titleColor, fontSize: 18, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
              if (isToday)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE31E24).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'HARI INI',
                    style: GoogleFonts.outfit(color: const Color(0xFFE31E24), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1),
                  ),
                ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF005596).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${dayEvents.length} ACARA',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF005596), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Event list ──
        Expanded(
          child: dayEvents.isEmpty
              ? _buildEmptyState(mutedColor)
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                  physics: const BouncingScrollPhysics(),
                  itemCount: dayEvents.length,
                  itemBuilder: (context, i) => FadeInUp(
                    delay: Duration(milliseconds: i * 80),
                    duration: const Duration(milliseconds: 300),
                    child: _buildEventCard(dayEvents[i], cardBg, titleColor, mutedColor, shadowColor),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildEventCard(
    CalendarEvent e,
    Color cardBg,
    Color titleColor,
    Color mutedColor,
    Color shadowColor,
  ) {
    final color = _categoryColor(e.category);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: shadowColor, blurRadius: 14, offset: const Offset(0, 4))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left accent bar
              Container(width: 4, color: color),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              e.category.toUpperCase(),
                              style: GoogleFonts.outfit(color: color, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.8),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: mutedColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.access_time_rounded, size: 10, color: mutedColor),
                                const SizedBox(width: 4),
                                Text(
                                  DateFormat('HH:mm').format(e.startDate),
                                  style: GoogleFonts.outfit(color: mutedColor, fontSize: 10, fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        e.title,
                        style: GoogleFonts.outfit(color: titleColor, fontSize: 15, fontWeight: FontWeight.w800, height: 1.2, letterSpacing: 0.1),
                      ),
                      if (e.description.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          e.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(color: mutedColor, fontSize: 12, fontWeight: FontWeight.w500, height: 1.45),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.location_on_rounded, size: 12, color: mutedColor.withValues(alpha: 0.7)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              e.location ?? 'Hub Martapura',
                              style: GoogleFonts.outfit(color: mutedColor, fontSize: 11, fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(Icons.people_rounded, size: 12, color: mutedColor.withValues(alpha: 0.7)),
                          const SizedBox(width: 4),
                          Text(
                            '${e.attendees.length + (e.departments?.length ?? 0)} Diundang',
                            style: GoogleFonts.outfit(color: mutedColor, fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(Color mutedColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_available_rounded, color: mutedColor.withValues(alpha: 0.3), size: 52),
          const SizedBox(height: 14),
          Text(
            'Tidak ada acara hari ini',
            style: GoogleFonts.outfit(color: mutedColor, fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Pilih tanggal lain atau hubungi Admin',
            style: GoogleFonts.outfit(color: mutedColor.withValues(alpha: 0.6), fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
