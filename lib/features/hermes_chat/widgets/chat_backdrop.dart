import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../settings/providers/chat_preferences_provider.dart';

/// Install-local decoration; the conversation always occupies the same slot.
class WingChatBackdrop extends ConsumerWidget {
  const WingChatBackdrop({required this.child, super.key});

  final Widget child;

  static const _invert = ColorFilter.matrix(<double>[
    -1,
    0,
    0,
    0,
    255,
    0,
    -1,
    0,
    0,
    255,
    0,
    0,
    -1,
    0,
    255,
    0,
    0,
    0,
    1,
    0,
  ]);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(
      wingChatPreferencesProvider.select((prefs) => prefs.backdropEnabled),
    );
    final theme = Theme.of(context);
    final surface = theme.colorScheme.surface;
    return Material(
      color: surface,
      child: ClipRect(
        key: const ValueKey('chat-backdrop-pane'),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: enabled
                  ? ExcludeSemantics(
                      key: const ValueKey('chat-backdrop-art'),
                      child: ExcludeFocus(
                        child: IgnorePointer(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              // The pinned art is square. Use this pane as the
                              // adaptive viewport rather than the entire window.
                              final height = constraints.maxHeight * 1.6;
                              final width = math.max(
                                constraints.maxWidth,
                                height,
                              );
                              Widget image = Image.asset(
                                'assets/desktop/filler-bg0.jpg',
                                width: width,
                                height: height,
                                fit: BoxFit.cover,
                                alignment: Alignment.topLeft,
                                excludeFromSemantics: true,
                                cacheWidth:
                                    (width *
                                            MediaQuery.devicePixelRatioOf(
                                              context,
                                            ))
                                        .ceil(),
                              );
                              if (theme.brightness == Brightness.light) {
                                image = ColorFiltered(
                                  colorFilter: _invert,
                                  child: image,
                                );
                              }
                              return OverflowBox(
                                alignment: Alignment.topLeft,
                                minWidth: width,
                                maxWidth: width,
                                minHeight: height,
                                maxHeight: height,
                                child: Opacity(
                                  opacity: 0.025,
                                  // Blend against only the opaque Chat surface;
                                  // never apply a filter to the foreground.
                                  child: ColorFiltered(
                                    colorFilter: ColorFilter.mode(
                                      surface,
                                      BlendMode.difference,
                                    ),
                                    child: image,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            Positioned.fill(child: child),
          ],
        ),
      ),
    );
  }
}
