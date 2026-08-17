import 'package:flutter/material.dart';
import '../../models/app_theme.dart';

void mostrarSelectorTemasModal(BuildContext context, AppThemeStyle currentStyle, Function(AppThemeStyle) onThemeChanged) {
  final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          final theme = AppThemeConfig.getTheme(currentStyle);

          return ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * (isLandscape ? 0.90 : 0.80),
            ),
            child: Container(
              margin: EdgeInsets.all(isLandscape ? 8 : 16),
              padding: EdgeInsets.all(isLandscape ? 14 : 24),
              decoration: BoxDecoration(
                color: theme.surfaceColor,
                borderRadius: BorderRadius.circular(theme.borderRadius),
                border: Border.all(color: theme.primaryColor.withValues(alpha: 0.5), width: 1.5),
                boxShadow: theme.shadows,
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.palette_rounded, color: theme.primaryColor, size: isLandscape ? 20 : 24),
                        const SizedBox(width: 10),
                        Text(
                          "MOTOR DE TEMAS VISUALES (6 ESTILOS)",
                          style: TextStyle(
                            color: theme.textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: isLandscape ? 12 : 14,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: Icon(Icons.close_rounded, color: theme.subtitleColor, size: isLandscape ? 18 : 24),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    SizedBox(height: isLandscape ? 8 : 16),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: isLandscape ? 3 : 2,
                        crossAxisSpacing: isLandscape ? 8 : 12,
                        mainAxisSpacing: isLandscape ? 8 : 12,
                        childAspectRatio: isLandscape ? 2.4 : 2.2,
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
              ),
            ),
          );
        },
      );
    },
  );
}
