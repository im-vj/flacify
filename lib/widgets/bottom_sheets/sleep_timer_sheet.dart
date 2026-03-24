import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/player_provider.dart';

class SleepTimerSheet extends ConsumerStatefulWidget {
  const SleepTimerSheet({super.key});

  @override
  ConsumerState<SleepTimerSheet> createState() => _SleepTimerSheetState();
}

class _SleepTimerSheetState extends ConsumerState<SleepTimerSheet> {
  Timer? _countdownTimer;
  Duration? _remainingTime;
  Duration? _selectedDuration;

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdown(Duration duration) {
    _countdownTimer?.cancel();
    _selectedDuration = duration;
    _remainingTime = duration;

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime == null || _remainingTime!.inSeconds <= 0) {
        timer.cancel();
        if (mounted) {
          ref.read(playerProvider.notifier).cancelSleepTimer();
          Navigator.pop(context);
        }
      } else {
        setState(() {
          _remainingTime = _remainingTime! - const Duration(seconds: 1);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final playerNotifier = ref.read(playerProvider.notifier);
    final playerState = ref.watch(playerProvider);
    final hasActiveTimer = playerState.sleepTimerEnd != null;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A2E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00F0FF).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.bedtime_rounded,
                      color: Color(0xFF00F0FF),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Sleep Timer',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Music will stop after selected time',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (hasActiveTimer && _remainingTime != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00F0FF).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.timer, color: Color(0xFF00F0FF), size: 14),
                          const SizedBox(width: 4),
                          Text(
                            _formatTime(_remainingTime!),
                            style: const TextStyle(
                              color: Color(0xFF00F0FF),
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            // Active timer card
            if (hasActiveTimer && _remainingTime != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildActiveTimerCard(playerNotifier),
              ),
              const SizedBox(height: 16),
            ],
            // Timer options
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  Row(
                    children: [
                      _TimerButton(
                        label: '5 min',
                        icon: Icons.coffee,
                        isSelected: _selectedDuration?.inMinutes == 5 && hasActiveTimer,
                        onTap: () {
                          playerNotifier.setSleepTimer(const Duration(minutes: 5));
                          _startCountdown(const Duration(minutes: 5));
                          Navigator.pop(context);
                        },
                      ),
                      const SizedBox(width: 10),
                      _TimerButton(
                        label: '15 min',
                        icon: Icons.weekend,
                        isSelected: _selectedDuration?.inMinutes == 15 && hasActiveTimer,
                        onTap: () {
                          playerNotifier.setSleepTimer(const Duration(minutes: 15));
                          _startCountdown(const Duration(minutes: 15));
                          Navigator.pop(context);
                        },
                      ),
                      const SizedBox(width: 10),
                      _TimerButton(
                        label: '30 min',
                        icon: Icons.tv,
                        isSelected: _selectedDuration?.inMinutes == 30 && hasActiveTimer,
                        onTap: () {
                          playerNotifier.setSleepTimer(const Duration(minutes: 30));
                          _startCountdown(const Duration(minutes: 30));
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _TimerButton(
                        label: '45 min',
                        icon: Icons.book,
                        isSelected: _selectedDuration?.inMinutes == 45 && hasActiveTimer,
                        onTap: () {
                          playerNotifier.setSleepTimer(const Duration(minutes: 45));
                          _startCountdown(const Duration(minutes: 45));
                          Navigator.pop(context);
                        },
                      ),
                      const SizedBox(width: 10),
                      _TimerButton(
                        label: '1 hour',
                        icon: Icons.nightlight_round,
                        isSelected: _selectedDuration?.inHours == 1 && hasActiveTimer,
                        onTap: () {
                          playerNotifier.setSleepTimer(const Duration(hours: 1));
                          _startCountdown(const Duration(hours: 1));
                          Navigator.pop(context);
                        },
                      ),
                      const SizedBox(width: 10),
                      _TimerButton(
                        label: '2 hours',
                        icon: Icons.bedtime,
                        isSelected: _selectedDuration?.inHours == 2 && hasActiveTimer,
                        onTap: () {
                          playerNotifier.setSleepTimer(const Duration(hours: 2));
                          _startCountdown(const Duration(hours: 2));
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Cancel button
            if (hasActiveTimer)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GestureDetector(
                  onTap: () {
                    playerNotifier.cancelSleepTimer();
                    _countdownTimer?.cancel();
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.close, color: Colors.white70, size: 18),
                        SizedBox(width: 6),
                        Text(
                          'Cancel Timer',
                          style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveTimerCard(PlayerNotifier playerNotifier) {
    final progress = 1 - (_remainingTime!.inSeconds / _selectedDuration!.inSeconds);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF00F0FF).withValues(alpha: 0.2),
            const Color(0xFF00F0FF).withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF00F0FF).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.bedtime_rounded, color: Color(0xFF00F0FF), size: 18),
              const SizedBox(width: 8),
              const Text(
                'Timer Active',
                style: TextStyle(
                  color: Color(0xFF00F0FF),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              Text(
                _formatTime(_remainingTime!),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 5,
              backgroundColor: Colors.white12,
              valueColor: const AlwaysStoppedAnimation(Color(0xFF00F0FF)),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds.remainder(60);
    if (minutes >= 60) {
      final hours = d.inHours;
      final mins = minutes.remainder(60);
      return '${hours}h ${mins}m';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

class _TimerButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _TimerButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF00F0FF).withValues(alpha: 0.15)
                : const Color(0xFF252540),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? const Color(0xFF00F0FF) : const Color(0x14FFFFFF),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? const Color(0xFF00F0FF) : Colors.white54,
                size: 22,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
