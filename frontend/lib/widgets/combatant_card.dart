import 'package:flutter/material.dart';
import '../models/encounter.dart';
import '../theme/app_theme.dart';

/// A card displaying a single combatant's initiative, name, HP, and HP controls.
class CombatantCard extends StatelessWidget {
  final Combatant combatant;
  final bool isActive;
  final VoidCallback onHpIncrease;
  final VoidCallback onHpDecrease;
  /// Callback for custom HP adjustment (e.g. opens a dialog for arbitrary delta).
  final VoidCallback? onHpCustomAdjust;

  const CombatantCard({
    super.key,
    required this.combatant,
    required this.isActive,
    required this.onHpIncrease,
    required this.onHpDecrease,
    this.onHpCustomAdjust,
  });

  Color get _accentColor =>
      combatant.isPlayer ? AppTheme.playerGreen : AppTheme.monsterRed;

  Color get _dimColor =>
      combatant.isPlayer ? AppTheme.playerGreenDim : AppTheme.monsterRedDim;

  /// Displays the initiative value, or '?' if the engine hasn't rolled yet.
  String get _initiativeLabel =>
      combatant.initiative != null ? '${combatant.initiative}' : '?';

  Color get _hpColor {
    final pct = combatant.hpPercent;
    if (pct > 0.5) return AppTheme.hpFull;
    if (pct > 0.25) return AppTheme.hpMid;
    return AppTheme.hpLow;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isActive ? _dimColor : AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive ? _accentColor : AppTheme.border,
          width: isActive ? 2 : 1,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: _accentColor.withValues(alpha: 0.25),
                  blurRadius: 16,
                  spreadRadius: 2,
                )
              ]
            : [],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 10),
            _buildHpBar(),
            const SizedBox(height: 8),
            _buildHpControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        // Initiative badge
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: _accentColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _accentColor.withValues(alpha: 0.4)),
          ),
          child: Center(
            child: Text(
              _initiativeLabel,
              style: TextStyle(
                color: _accentColor,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Name + type
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (isActive) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _accentColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'ACTIVE',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Flexible(
                    child: Text(
                      combatant.name,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                combatant.isPlayer ? '⚔ Player' : '☠ Monster',
                style: TextStyle(
                  color: _accentColor.withValues(alpha: 0.7),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        // HP display
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${combatant.currentHp}',
              style: TextStyle(
                color: _hpColor,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              '/ ${combatant.maxHp} HP',
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 11),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHpBar() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: combatant.hpPercent.clamp(0.0, 1.0),
        minHeight: 5,
        backgroundColor: AppTheme.border,
        valueColor: AlwaysStoppedAnimation<Color>(_hpColor),
      ),
    );
  }

  Widget _buildHpControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        _HpButton(
          icon: Icons.remove,
          color: AppTheme.monsterRed,
          onPressed: combatant.currentHp > 0 ? onHpDecrease : null,
        ),
        const SizedBox(width: 6),
        // Custom delta button — opens a dialog in the parent screen
        if (onHpCustomAdjust != null) ...[
          _HpButton(
            icon: Icons.edit_outlined,
            color: AppTheme.textSecondary,
            onPressed: onHpCustomAdjust,
            tooltip: 'Custom adjust',
          ),
          const SizedBox(width: 6),
        ],
        _HpButton(
          icon: Icons.add,
          color: AppTheme.playerGreen,
          onPressed:
              combatant.currentHp < combatant.maxHp ? onHpIncrease : null,
        ),
      ],
    );
  }
}

class _HpButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;
  final String? tooltip;

  const _HpButton({
    required this.icon,
    required this.color,
    this.onPressed,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final button = GestureDetector(
      onTap: onPressed,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: onPressed != null ? 1.0 : 0.3,
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.5)),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: button);
    }
    return button;
  }
}
