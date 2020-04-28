library chokelever;

import 'dart:math';
import 'package:flutter/material.dart';

class ChokeLever extends StatefulWidget {
  final double width;
  final double height;
  final Image image = Image.asset('assets/iconChokeLeverHandle.png');
  final double initialSpinAngle = 0;
  final double spinResistance = 0.5;

  ChokeLever({this.width, this.height});
  @override
  _ChokeLeverState createState() => _ChokeLeverState();
}

const Duration DEFAULT_TIME_INTERVAL =
    Duration(milliseconds: 500); //  0.5 second

class _ChokeLeverState extends State<ChokeLever>
    with SingleTickerProviderStateMixin {
  AnimationController _animationController;
  SpinVelocity _spinVelocity;
  Offset _localPositionOnPanUpdate;
  double _rotationAngle = 0;
  DateTime _offsetOutsideTimestamp;
  RenderBox _renderBox;
  bool isDragging;

  @override
  void initState() {
    super.initState();

    _spinVelocity = SpinVelocity(width: widget.width, height: widget.height);

    _animationController = new AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 500),
        lowerBound: 0,
        upperBound: 10);

    _animationController.animateTo(0, duration: DEFAULT_TIME_INTERVAL);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(border: Border.all(width: 5)),
      height: widget.height,
      width: widget.width,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image.asset("assets/iconChokeLeverBackground.png"),
          GestureDetector(
            onPanStart: _dragStart,
            onPanUpdate: _dragUpdate,
            onPanEnd: (_details) => _stopAnimation(),
            child: AnimatedBuilder(
                animation: _animationController,
                child: Container(child: widget.image),
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _animationController.value,
                    child: child,
                  );
                }),
          ),
        ],
      ),
    );
  }

  bool get _userCanInteract => !_animationController.isAnimating;

  // transforms from global coordinates to local and store the value
  void _updateLocalPosition(Offset position) {
    if (_renderBox == null) {
      _renderBox = context.findRenderObject();
    }
    _localPositionOnPanUpdate = _renderBox.globalToLocal(position);
  }

  /// returns true if (x,y) is outside the boundaries from size
  bool _contains(Offset p) => Size(widget.width, widget.height).contains(p);

  void _dragStart(DragStartDetails details) {
    print("_dragStart");
    _moveWheel(details.globalPosition);
  }

  void _dragUpdate(DragUpdateDetails details) {
    print("_dragUpdate");
    _moveWheel(details.globalPosition);
  }

  void _moveWheel(Offset globalPosition) {
    isDragging = true;
    if (!_userCanInteract) return;

    if (_offsetOutsideTimestamp != null) return;

    _updateLocalPosition(globalPosition);

    if (_contains(_localPositionOnPanUpdate)) {
      var angle = _spinVelocity.offsetToRadians(_localPositionOnPanUpdate);
      setState(() {
        _rotationAngle = angle;
        if (_rotationAngle > 0.45 && _rotationAngle < 3) {
          _rotationAngle = 0.45;
        }
        if (_rotationAngle < 6.27 - 0.45 && _rotationAngle > 3) {
          _rotationAngle = 6.27 - 0.45;
        }
        print("Actual _rotationAngle $_rotationAngle");
        // if (_rotationAngle > 0.45) {
        //   _rotationAngle = 0.45;
        // }
        // if (_rotationAngle < -0.45) {
        //   _rotationAngle = -0.45;
        // }

        _animationController.animateTo(_rotationAngle,
            duration: Duration(microseconds: 500));
      });
    }
  }

  void _stopAnimation() {
    _offsetOutsideTimestamp = null;

    setState(() {
      isDragging = false;

      if (_animationController.value > 5) {
        _animationController.animateTo(6.27,
            duration: Duration(milliseconds: 300));
      } else {
        _animationController.animateTo(0,
            duration: Duration(milliseconds: 300));
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    //WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}

const Map<int, Offset> cuadrants = const {
  1: Offset(0.5, 0.5),
  2: Offset(-0.5, 0.5),
  3: Offset(-0.5, -0.5),
  4: Offset(0.5, -0.5),
};

const pi_0_5 = pi * 0.5;
const pi_2_5 = pi * 2.5;
const pi_2 = pi * 2;

class SpinVelocity {
  final double height;
  final double width;

  double get width_0_5 => width / 2;
  double get height_0_5 => height / 2;

  SpinVelocity({@required this.height, @required this.width});

  /// transforms (x,y) into radians assuming we start at positive y axis as 0
  double offsetToRadians(Offset position) {
    print("position.dx $position.dx position.dy $position.dy");
    var a = position.dx - width_0_5;
    var b = height_0_5 - position.dy;
    var angle = atan2(b, a);
    return normalizeAngle(angle);
    //return angle;
  }

  // radians go from 0 to pi (positive y axis) and 0 to -pi (negative y axis)
  // we need radians from positive y axis (0) clockwise back to y axis (2pi)
  double normalizeAngle(double angle) => angle > 0
      ? (angle > pi_0_5 ? (pi_2_5 - angle) : (pi_0_5 - angle))
      : pi_0_5 - angle;

  bool contains(Offset p) => Size(width, height).contains(p);
}
