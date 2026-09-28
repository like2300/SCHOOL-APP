import 'package:flutter/material.dart';

class Days extends StatefulWidget {
  final ValueChanged<DateTime> onDaySelected;
  final DateTime? selectedDay;
  final bool compact;

  const Days({
    super.key,
    required this.onDaySelected,
    this.selectedDay,
    this.compact = false,
  });

  @override
  State<Days> createState() => _DaysState();
}

class _DaysState extends State<Days> {
  late DateTime _currentWeekStart;
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = widget.selectedDay ?? DateTime.now();
    _currentWeekStart = _getWeekStart(_selectedDay);
  }

  @override
  void didUpdateWidget(covariant Days oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedDay != null && widget.selectedDay != _selectedDay) {
      _selectedDay = widget.selectedDay!;
      final newWeekStart = _getWeekStart(_selectedDay);
      if (newWeekStart != _currentWeekStart) {
        setState(() => _currentWeekStart = newWeekStart);
      }
    }
  }

  DateTime _getWeekStart(DateTime date) {
    final weekday = date.weekday;
    return date.subtract(Duration(days: weekday - 1));
  }

  void _goToPreviousWeek() {
    setState(() {
      _currentWeekStart = _currentWeekStart.subtract(const Duration(days: 7));
    });
  }

  void _goToNextWeek() {
    setState(() {
      _currentWeekStart = _currentWeekStart.add(const Duration(days: 7));
    });
  }

  void _goToToday() {
    final today = DateTime.now();
    setState(() {
      _selectedDay = today;
      _currentWeekStart = _getWeekStart(today);
    });
    widget.onDaySelected(today);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return _isSameDay(date, now);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final days =
        List.generate(7, (i) => _currentWeekStart.add(Duration(days: i)));

    if (widget.compact) {
      return _buildCompactDays(days, colorScheme);
    }
    return _buildFullDays(days, colorScheme);
  }

  Widget _buildFullDays(List<DateTime> days, ColorScheme colorScheme) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: Icon(Icons.chevron_left_rounded,
                  color: colorScheme.onSurfaceVariant),
              onPressed: _goToPreviousWeek,
              style: IconButton.styleFrom(
                backgroundColor:
                    colorScheme.surfaceContainerHighest.withOpacity(0.5),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            GestureDetector(
              onTap: _goToToday,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getWeekRange(),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.chevron_right_rounded,
                  color: colorScheme.onSurfaceVariant),
              onPressed: _goToNextWeek,
              style: IconButton.styleFrom(
                backgroundColor:
                    colorScheme.surfaceContainerHighest.withOpacity(0.5),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: days.map((day) {
            final isSelected = _isSameDay(day, _selectedDay);
            final isToday = _isToday(day);

            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() => _selectedDay = day);
                  widget.onDaySelected(day);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colorScheme.primary
                        : isToday
                            ? colorScheme.primaryContainer.withOpacity(0.5)
                            : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    border: isToday && !isSelected
                        ? Border.all(
                            color: colorScheme.primary.withOpacity(0.3),
                            width: 1.5)
                        : null,
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: colorScheme.primary.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    children: [
                      Text(
                        _getDayAbbr(day),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? colorScheme.onPrimary.withOpacity(0.8)
                              : colorScheme.onSurfaceVariant,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        day.day.toString(),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? colorScheme.onPrimary
                              : colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCompactDays(List<DateTime> days, ColorScheme colorScheme) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _getWeekRange(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildCompactNavButton(
                    Icons.chevron_left_rounded, _goToPreviousWeek, colorScheme),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: _goToToday,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Auj.',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                _buildCompactNavButton(
                    Icons.chevron_right_rounded, _goToNextWeek, colorScheme),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: days.map((day) {
            final isSelected = _isSameDay(day, _selectedDay);
            final isToday = _isToday(day);

            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() => _selectedDay = day);
                  widget.onDaySelected(day);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colorScheme.primary
                        : isToday
                            ? colorScheme.primaryContainer.withOpacity(0.4)
                            : colorScheme.surfaceContainerHighest
                                .withOpacity(0.4),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _getDayAbbr(day)[0],
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? colorScheme.onPrimary.withOpacity(0.7)
                              : colorScheme.onSurfaceVariant,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        day.day.toString(),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? colorScheme.onPrimary
                              : colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCompactNavButton(
      IconData icon, VoidCallback onTap, ColorScheme colorScheme) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(icon, size: 18, color: colorScheme.onSurfaceVariant),
        ),
      ),
    );
  }

  String _getDayAbbr(DateTime day) {
    const abbr = ['LUN', 'MAR', 'MER', 'JEU', 'VEN', 'SAM', 'DIM'];
    return abbr[day.weekday - 1];
  }

  String _getWeekRange() {
    final end = _currentWeekStart.add(const Duration(days: 6));
    const mois = [
      'Jan',
      'Fév',
      'Mar',
      'Avr',
      'Mai',
      'Juin',
      'Juil',
      'Août',
      'Sep',
      'Oct',
      'Nov',
      'Déc'
    ];
    return '${_currentWeekStart.day} ${mois[_currentWeekStart.month - 1]} → ${end.day} ${mois[end.month - 1]}';
  }
}
