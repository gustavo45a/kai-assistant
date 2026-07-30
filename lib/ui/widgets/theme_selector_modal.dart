import 'package:flutter/material.dart';
import '../../models/app_theme.dart';

void mostrarSelectorTemasModal(BuildContext context, AppThemeStyle currentStyle, Function(AppThemeStyle) onThemeChanged) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          final theme = AppThemeConfig.getTheme(currentStyle);

          return Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.surfaceColor,
              borderRadius: BorderRadius.circular(theme.borderRadius),
              border: Border.all(color: theme.primaryColor.withValues(alpha: 0.5), width: 1.5),
              boxShadow: theme.shadows,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.palette_rounded, color: theme.primaryColor, size: 24),
                    const SizedBox(width: 10),
                    Text(
                      "MOTOR DE TEMAS VISUALES (6 ESTILOS)",
                      style: TextStyle(
                        color: theme.textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(Icons.close_rounded, color: theme.subtitleColor),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 2.2,
                  ),
                  itemCount: AppThemeStyle.values.length,
                  itemBuilder: (context, index) {
                    final itemStyle = AppThemeStyle.values[index];
                    final itemTheme = AppThemeConfig.getTheme(itemStyle);
                    final isSelected = itemStyle == currentStyle;

                    return InkWell(
                      onTap: () {
                        onThemeChanged(itemStyle);
                        setModalState(() {
                          currentStyle = itemStyle;
                        });
                      },
                      borderRadius: BorderRadius.circular(itemTheme.borderRadius),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: itemTheme.cardColor,
                          borderRadius: BorderRadius.circular(itemTheme.borderRadius),
                          border: Border.all(
                            color: isSelected ? itemTheme.primaryColor : itemTheme.borderColor.withValues(alpha: 0.4),
                            width: isSelected ? 2.0 : 1.0,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(itemTheme.icon, color: itemTheme.primaryColor, size: 18),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    itemTheme.name,
                                    style: TextStyle(
                                      color: itemTheme.textColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isSelected)
                                  Icon(Icons.check_circle_rounded, color: itemTheme.primaryColor, size: 16),
                              ],
                            ),
                            Text(
                              itemTheme.description,
                              style: TextStyle(color: itemTheme.subtitleColor, fontSize: 9.5),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
