import 'package:flutter/material.dart';

class SlideTransitionDirection {
  static const String left = 'left';
  static const String right = 'right';
  static const String top = 'top';
  static const String bottom = 'bottom';
}

class SlideTransitionClass extends PageRouteBuilder {
  final Widget page;
  final String direction;

  SlideTransitionClass({required this.page, required this.direction})
      : super(
          pageBuilder: (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
          ) =>
              page,
          transitionsBuilder: (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
            Widget child,
          ) {
            Offset begin;
            Offset end;

            switch (direction) {
              case SlideTransitionDirection.left:
                begin = const Offset(1.0, 0.0);
                end = const Offset(0.0, 0.0);
                break;
              case SlideTransitionDirection.right:
                begin = const Offset(-1.0, 0.0);
                end = const Offset(0.0, 0.0);
                break;
              case SlideTransitionDirection.top: // Nueva dirección: arriba
                begin = const Offset(0.0, -1.0);
                end = const Offset(0.0, 0.0);
                break;
              case SlideTransitionDirection.bottom: // Nueva dirección: abajo
                begin = const Offset(0.0, 1.0);
                end = const Offset(0.0, 0.0);
                break;
              default:
                throw ArgumentError(
                    'Invalid direction. Use "left", "right", "top", or "bottom".');
            }

            var tween = Tween(begin: begin, end: end)
                .chain(CurveTween(curve: Curves.easeInOut));

            var offsetAnimation = animation.drive(tween);

            return SlideTransition(position: offsetAnimation, child: child);
          },
        );
}
