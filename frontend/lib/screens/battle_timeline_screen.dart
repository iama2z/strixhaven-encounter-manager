import 'package:flutter/material.dart';
import '../models/encounter.dart';
import '../services/encounter_service.dart';
import '../theme/app_theme.dart';
import '../widgets/combatant_card.dart';

/// The main battle timeline screen. Uses a StreamBuilder to listen to
/// real-time Firestore updates and rebuilds whenever the encounter changes.
class BattleTimelineScreen extends StatefulWidget {
  final String encounterId;
  final EncounterService service;

  const BattleTimelineScreen({
    super.key,
    required this.encounterId,
    required this.service,
  });

  @override
  State<BattleTimelineScreen> createState() => _BattleTimelineScreenState();
}

class _BattleTimelineScreenState extends State<BattleTimelineScreen> {
  bool _isLoading = false;

  Future<void> _run(Future<void> Function() action) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      await action();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.monsterRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: StreamBuilder<Encounter?>(
          stream: widget.service.watchEncounter(widget.encounterId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: AppTheme.accent),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Text('Error: ${snapshot.error}',
                    style: const TextStyle(color: AppTheme.monsterRed)),
              );
            }

            final encounter = snapshot.data;
            if (encounter == null) {
              return const Center(
                child: Text('Encounter not found.',
                    style: TextStyle(color: AppTheme.textSecondary)),
              );
            }

            return SafeArea(
              child: Column(
                children: [
                  _buildHeader(encounter),
                  Expanded(child: _buildTimeline(encounter)),
                  _buildControls(encounter),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(Encounter encounter) {
    final active = encounter.activeCombatant;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        border: const Border(bottom: BorderSide(color: AppTheme.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
          )
        ],
      ),
      child: Row(
        children: [
          // Title + round
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      '⚡ ',
                      style: TextStyle(fontSize: 20),
                    ),
                    const Text(
                      'Battle Timeline',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Round ${encounter.round}  •  ${encounter.combatants.length} combatants',
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
          // Status chip
          _StatusChip(status: encounter.status),
        ],
      ),
    );
  }

  Widget _buildTimeline(Encounter encounter) {
    if (encounter.combatants.isEmpty) {
      return const Center(
        child: Text('No combatants in this encounter.',
            style: TextStyle(color: AppTheme.textSecondary)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: encounter.combatants.length,
      itemBuilder: (context, index) {
        final combatant = encounter.combatants[index];
        final isActive = index == encounter.currentTurnIndex &&
            encounter.status == 'active';
        return CombatantCard(
          combatant: combatant,
          isActive: isActive,
          onHpIncrease: () => _run(
            () => widget.service.adjustHp(encounter, combatant.id, 1),
          ),
          onHpDecrease: () => _run(
            () => widget.service.adjustHp(encounter, combatant.id, -1),
          ),
        );
      },
    );
  }

  Widget _buildControls(Encounter encounter) {
    final isActive = encounter.status == 'active';
    final isSetup = encounter.status == 'setup';
    final isCompleted = encounter.status == 'completed';

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        border: const Border(top: BorderSide(color: AppTheme.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
          )
        ],
      ),
      child: Row(
        children: [
          // Previous turn
          _ControlButton(
            icon: Icons.skip_previous_rounded,
            label: 'Prev',
            onPressed: isActive && encounter.currentTurnIndex > 0
                ? () => _run(() => widget.service.previousTurn(encounter))
                : null,
          ),
          const Spacer(),

          // Main action button
          if (isSetup)
            _PrimaryButton(
              label: 'Start Encounter',
              icon: Icons.play_arrow_rounded,
              color: AppTheme.playerGreen,
              onPressed: _isLoading
                  ? null
                  : () => _run(
                      () => widget.service.startEncounter(encounter.id)),
            )
          else if (isActive)
            _PrimaryButton(
              label: 'Next Turn',
              icon: Icons.skip_next_rounded,
              color: AppTheme.accent,
              onPressed: _isLoading
                  ? null
                  : () => _run(() => widget.service.nextTurn(encounter)),
            )
          else if (isCompleted)
            const Text(
              '🏁 Encounter Complete',
              style: TextStyle(color: AppTheme.gold, fontSize: 15),
            ),

          const Spacer(),

          // End encounter
          _ControlButton(
            icon: Icons.stop_rounded,
            label: 'End',
            color: AppTheme.monsterRed,
            onPressed: isActive
                ? () => _run(
                    () => widget.service.endEncounter(encounter.id))
                : null,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Small supporting widgets
// ---------------------------------------------------------------------------

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'active' => ('● ACTIVE', AppTheme.playerGreen),
      'completed' => ('✓ DONE', AppTheme.textSecondary),
      _ => ('SETUP', AppTheme.gold),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
            color: color, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final Color color;

  const _ControlButton({
    required this.icon,
    required this.label,
    this.onPressed,
    this.color = AppTheme.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return GestureDetector(
      onTap: onPressed,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: enabled ? 1.0 : 0.3,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(color: color, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;

  const _PrimaryButton({
    required this.label,
    required this.icon,
    required this.color,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withOpacity(0.7)],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.35),
              blurRadius: 12,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.black, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
