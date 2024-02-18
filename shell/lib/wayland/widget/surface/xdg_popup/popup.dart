import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shell/wayland/model/wl_surface.dart';
import 'package:shell/wayland/provider/surface.manager.dart';
import 'package:shell/wayland/provider/wl_surface_state.dart';
import 'package:shell/wayland/provider/xdg_popup_state.dart';
import 'package:shell/wayland/provider/xdg_surface_state.dart';
import 'package:shell/wayland/widget/surface.dart';

class PopupWidget extends StatelessWidget {
  const PopupWidget({
    required this.surfaceId,
    super.key,
  });

  final SurfaceId surfaceId;

  @override
  Widget build(BuildContext context) {
    return _Positioner(
      surfaceId: surfaceId,
      child: SurfaceWidget(
        surfaceId: surfaceId,
      ),
    );
  }
}

class _Positioner extends HookConsumerWidget {
  const _Positioner({
    required this.surfaceId,
    required this.child,
  });

  final SurfaceId surfaceId;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final position = ref.watch(
      xdgPopupStateProvider(surfaceId).select((v) => v.position),
    );

    final firstParentId = ref.watch(
      xdgPopupStateProvider(surfaceId).select((v) => v.parent),
    );
    var offset = position;
    var parentId = firstParentId;

    // Sum recursively parent position until we reach the toplevel
    while (ref
        .read(xdgSurfaceStateProvider(surfaceId))
        .popups
        .contains(parentId)) {
      final parent = ref.read(
        xdgPopupStateProvider(parentId),
      );
      offset += parent.position;
      parentId = parent.parent;
    }

    return Positioned(
      left: offset.dx,
      top: offset.dy,
      child: child,
    );
  }
}

class _Animations extends ConsumerStatefulWidget {
  const _Animations({
    required this.surfaceId,
    required this.child,
    super.key,
  });

  final SurfaceId surfaceId;
  final Widget child;

  @override
  ConsumerState<_Animations> createState() => AnimationsState();
}

class AnimationsState extends ConsumerState<_Animations>
    with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        transformHitTests: false,
        position: _offsetAnimation,
        child: widget.child,
      ),
    );
  }

  late final AnimationController controller = AnimationController(
    duration: const Duration(milliseconds: 200),
    reverseDuration: const Duration(milliseconds: 100),
    vsync: this,
  )..forward();

  late final Animation<Offset> _offsetAnimation = Tween<Offset>(
    begin: Offset(
      0,
      -10.0 /
          ref.read(wlSurfaceStateProvider(widget.surfaceId)).surfaceSize.height,
    ),
    end: Offset.zero,
  ).animate(
    CurvedAnimation(
      parent: controller,
      curve: Curves.easeOutCubic,
    ),
  );

  late final Animation<double> _fadeAnimation = Tween<double>(
    begin: 0,
    end: 1,
  ).animate(
    CurvedAnimation(
      parent: controller,
      curve: Curves.easeOutCubic,
    ),
  );

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
