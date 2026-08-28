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
            content: const Text('Something went wrong. Please try again.'),
            backgroundColor: AppTheme.monsterRed,
          ),
        );
        debugPrint('BattleTimelineScreen error: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmEndEncounter(Encounter encounter) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text(
          'End Encounter?',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        content: const Text(
          'This will mark the encounter as completed. Are you sure?',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('End',
                style: TextStyle(color: AppTheme.monsterRed)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _run(() => widget.service.endEncounter(encounter.id));
    }
  }

  Future<void> _confirmResetEncounter(Encounter encounter) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text(
          'Reset Encounter?',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        content: const Text(
          'This will reset the encounter to setup and restore all combatants to full HP.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Reset',
                style: TextStyle(color: AppTheme.monsterRed)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _run(() => widget.service.resetEncounter(encounter));
    }
  }

  Future<void> _showSetRoundDialog(Encounter encounter) async {
    final controller = TextEditingController(text: '${encounter.round}');
    final round = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text(
          'Set Round',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        content: TextField(
          controller: controller,
          keyboardType:
              const TextInputType.numberWithOptions(signed: false, decimal: false),
          autofocus: true,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: InputDecoration(
            hintText: 'Enter round number',
            hintStyle: const TextStyle(color: AppTheme.textMuted),
            filled: true,
            fillColor: AppTheme.surfaceVariant,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppTheme.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppTheme.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppTheme.accent),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text('Cancel',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              final value = int.tryParse(controller.text.trim());
              Navigator.of(ctx).pop(value);
            },
            child: const Text('Apply', style: TextStyle(color: AppTheme.accent)),
          ),
        ],
      ),
    );

    if (round != null && round > 0) {
      await _run(() => widget.service.setRound(encounter, round));
    }
  }

  Future<void> _handleBattleMenuAction(
    _BattleMenuAction action,
    Encounter encounter,
  ) async {
    switch (action) {
      case _BattleMenuAction.setRound:
        await _showSetRoundDialog(encounter);
      case _BattleMenuAction.resetTurn:
        await _run(() => widget.service.setCurrentTurnIndex(encounter, 0));
      case _BattleMenuAction.resetHp:
        await _run(() => widget.service.resetAllHp(encounter));
      case _BattleMenuAction.resetBattle:
        await _confirmResetEncounter(encounter);
    }
  }

  /// Shows a dialog prompting the user for an HP delta (positive = heal,
  /// negative = damage). Returns null if the user cancelled.
  Future<void> _showAdjustHpDialog(
      Encounter encounter, String combatantId) async {
    final controller = TextEditingController();
    final delta = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text(
          'Adjust HP',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(
              signed: true, decimal: false),
          autofocus: true,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: InputDecoration(
            hintText: 'e.g. -8 for damage, +5 for healing',
            hintStyle: const TextStyle(color: AppTheme.textMuted),
            filled: true,
            fillColor: AppTheme.surfaceVariant,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppTheme.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppTheme.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppTheme.accent),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text('Cancel',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              final value = int.tryParse(controller.text.trim());
              Navigator.of(ctx).pop(value);
            },
            child: const Text('Apply',
                style: TextStyle(color: AppTheme.accent)),
          ),
        ],
      ),
    );
    if (delta != null && delta != 0) {
      await _run(
          () => widget.service.adjustHp(encounter, combatantId, delta));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: StreamBuilder<Encounter?>(
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
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Encounter not found.',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : () => _run(() => widget.service
                              .createEncounterIfMissing(widget.encounterId)),
                      child: const Text('Create Encounter'),
                    ),
                  ],
                ),
              ),
            );
          }

          return Column(
            children: [
              _buildHeader(encounter),
              Expanded(child: _buildTimeline(encounter)),
              _buildControls(encounter),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(Encounter encounter) {
    final active = encounter.activeCombatant;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 56, 20, 16),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(bottom: BorderSide(color: AppTheme.border)),
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
          const SizedBox(width: 8),
          _BattleMenuButton(
            isLoading: _isLoading,
            onSelected: (action) => _handleBattleMenuAction(action, encounter),
          ),
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

    enum _BattleMenuAction {
      setRound,
      resetTurn,
      resetHp,
      resetBattle,
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
          onHpCustomAdjust: () =>
              _showAdjustHpDialog(encounter, combatant.id),
        );
      },
    );
  }

  Widget _buildControls(Encounter encounter) {
    final isActive = encounter.status == 'active';
    final isSetup = encounter.status == 'setup';
    final isCompleted = encounter.status == 'completed';

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: AppTheme.border)),
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

          // End encounter — requires confirmation
          _ControlButton(
            icon: Icons.stop_rounded,
            label: 'End',
            color: AppTheme.monsterRed,
            onPressed: isActive
                ? () => _confirmEndEncounter(encounter)
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
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
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
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withValues(alpha: 0.3)),
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
            colors: [color, color.withValues(alpha: 0.7)],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.35),
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

class _BattleMenuButton extends StatelessWidget {
  final bool isLoading;
  final ValueChanged<_BattleMenuAction> onSelected;

  const _BattleMenuButton({
    required this.isLoading,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_BattleMenuAction>(
      enabled: !isLoading,
      color: AppTheme.surfaceVariant,
      icon: const Icon(Icons.tune_rounded, color: AppTheme.textSecondary),
      tooltip: 'Battle menu',
      onSelected: onSelected,
      itemBuilder: (_) => const [
        PopupMenuItem<_BattleMenuAction>(
          value: _BattleMenuAction.setRound,
          child: Text('Set round',
              style: TextStyle(color: AppTheme.textPrimary)),
        ),
        PopupMenuItem<_BattleMenuAction>(
          value: _BattleMenuAction.resetTurn,
          child: Text('Reset to first turn',
              style: TextStyle(color: AppTheme.textPrimary)),
        ),
        PopupMenuItem<_BattleMenuAction>(
          value: _BattleMenuAction.resetHp,
          child: Text('Restore all HP',
              style: TextStyle(color: AppTheme.textPrimary)),
        ),
        PopupMenuDivider(),
        PopupMenuItem<_BattleMenuAction>(
          value: _BattleMenuAction.resetBattle,
          child: Text('Reset battle',
              style: TextStyle(color: AppTheme.monsterRed)),
        ),
      ],
    );
  }
}
