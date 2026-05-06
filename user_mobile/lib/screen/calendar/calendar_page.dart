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
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  static const Color jneBlue = Color(0xFF005596);
  static const Color jneRed = Color(0xFFE31E24);
  static const Color slate950 = Color(0xFF0F172A);

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final user = provider.currentUser;
    
    // Filter events based on user department or if they are invited
    final events = provider.events.where((e) {
      final matchDept = e.departments?.contains(user?.department) ?? false;
      final matchUser = e.attendees.contains(user?.uid);
      return matchDept || matchUser;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: slate950,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'SMART CALENDAR',
          style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 1.5),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // ── Calendar Grid ──
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: slate950,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
            child: Column(
              children: [
                _buildMonthSelector(),
                const SizedBox(height: 20),
                _buildDaysOfWeek(),
                const SizedBox(height: 10),
                _buildCalendarGrid(events),
              ],
            ),
          ),

          // ── Events for Selected Day ──
          Expanded(
            child: _buildEventList(events),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left_rounded, color: Colors.white),
          onPressed: () => setState(() => _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1)),
        ),
        Text(
          DateFormat('MMMM yyyy', 'id').format(_focusedDay).toUpperCase(),
          style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right_rounded, color: Colors.white),
          onPressed: () => setState(() => _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1)),
        ),
      ],
    );
  }

  Widget _buildDaysOfWeek() {
    final days = ['S', 'S', 'R', 'K', 'J', 'S', 'M'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: days.map((d) => Text(
        d,
        style: GoogleFonts.outfit(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.w800),
      )).toList(),
    );
  }

  Widget _buildCalendarGrid(List<CalendarEvent> events) {
    final daysInMonth = DateTime(_focusedDay.year, _focusedDay.month + 1, 0).day;
    final firstDayOffset = DateTime(_focusedDay.year, _focusedDay.month, 1).weekday - 1;
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: daysInMonth + firstDayOffset,
      itemBuilder: (context, index) {
        if (index < firstDayOffset) return const SizedBox();
        
        final day = index - firstDayOffset + 1;
        final date = DateTime(_focusedDay.year, _focusedDay.month, day);
        final isSelected = _selectedDay.day == day && _selectedDay.month == _focusedDay.month && _selectedDay.year == _focusedDay.year;
        final isToday = DateTime.now().day == day && DateTime.now().month == _focusedDay.month && DateTime.now().year == _focusedDay.year;
        
        // Check for events on this day
        final hasEvents = events.any((e) => isSameDay(e.startDate, date));

        return GestureDetector(
          onTap: () => setState(() => _selectedDay = date),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              color: isSelected ? jneRed : isToday ? Colors.white12 : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              border: isToday ? Border.all(color: jneRed.withValues(alpha: 0.5), width: 1) : null,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  day.toString(),
                  style: GoogleFonts.outfit(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontSize: 14,
                    fontWeight: isSelected || isToday ? FontWeight.w900 : FontWeight.w600,
                  ),
                ),
                if (hasEvents && !isSelected)
                  Positioned(
                    bottom: 6,
                    child: Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(color: jneRed, shape: BoxShape.circle),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEventList(List<CalendarEvent> events) {
    final dayEvents = events.where((e) => isSameDay(e.startDate, _selectedDay)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('EEEE, d MMMM', 'id').format(_selectedDay),
                style: GoogleFonts.outfit(color: slate950, fontSize: 18, fontWeight: FontWeight.w900),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: jneBlue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: Text(
                  '${dayEvents.length} ACARA',
                  style: GoogleFonts.outfit(color: jneBlue, fontSize: 10, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: dayEvents.isEmpty
            ? _buildEmptyState()
            : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: dayEvents.length,
                itemBuilder: (context, index) {
                  final e = dayEvents[index];
                  return FadeInUp(
                    delay: Duration(milliseconds: index * 100),
                    child: _buildEventCard(e),
                  );
                },
              ),
        ),
      ],
    );
  }

  Widget _buildEventCard(CalendarEvent e) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _getCategoryColor(e.category).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  e.category.toUpperCase(),
                  style: GoogleFonts.outfit(color: _getCategoryColor(e.category), fontSize: 9, fontWeight: FontWeight.w900),
                ),
              ),
              const Spacer(),
              Text(
                DateFormat('HH:mm').format(e.startDate),
                style: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            e.title,
            style: GoogleFonts.outfit(color: slate950, fontSize: 16, fontWeight: FontWeight.w900, height: 1.2),
          ),
          if (e.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              e.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.location_on_rounded, size: 14, color: Color(0xFF94A3B8)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  e.location ?? 'Hub Martapura',
                  style: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.people_rounded, size: 14, color: Color(0xFF94A3B8)),
              const SizedBox(width: 6),
              Text(
                '${e.attendees.length + (e.departments?.length ?? 0)} Diundang',
                style: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today_rounded, color: const Color(0xFFCBD5E1), size: 48),
          const SizedBox(height: 16),
          Text(
            'Tidak ada acara terjadwal',
            style: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 14, fontWeight: FontWeight.w700),
          ),
          Text(
            'Pilih tanggal lain atau hubungi Admin',
            style: GoogleFonts.outfit(color: const Color(0xFFCBD5E1), fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String cat) {
    switch (cat) {
      case 'meeting': return jneBlue;
      case 'training': return Colors.purple;
      case 'deadline': return jneRed;
      case 'social': return Colors.orange;
      default: return const Color(0xFF64748B);
    }
  }

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
