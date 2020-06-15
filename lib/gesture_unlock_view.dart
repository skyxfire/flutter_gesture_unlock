import 'dart:async';

import 'package:flutter/material.dart';

import 'unlock_line_painter.dart';
import 'unlock_point.dart';
import 'unlock_point_painter.dart';

enum UnlockType { solid, hollow }

enum UnlockStatus { normal, success, failed, disable }

class GestureUnlockView extends StatefulWidget {
  ///控件大小
  final double size;

  ///解锁类型（实心、空心）
  final UnlockType type;

  ///与父布局的间距
  final double padding;

  ///圆之间的间距
  final double roundSpace;

  ///圆之间的间距比例(以圆半径作为基准)，[roundSpace]设置时无效
  final double roundSpaceRatio;

  ///默认颜色
  final Color defaultColor;

  ///选中颜色
  final Color selectedColor;

  ///验证失败颜色
  final Color failedColor;

  ///无法使用颜色
  final Color disableColor;

  ///线长度
  final double lineWidth;

  ///实心圆半径比例(以圆半径作为基准)
  final double solidRadiusRatio;

  ///触摸有效区半径比例(以圆半径作为基准)
  final double touchRadiusRatio;

  ///延迟显示时间
  final int delayTime;

  ///回调
  final Function(List<int>, UnlockStatus) onCompleted;

  GestureUnlockView({
    Key key,
    @required this.size,
    this.type = UnlockType.solid,
    this.padding = 10,
    this.roundSpace,
    this.roundSpaceRatio = 0.6,
    this.defaultColor = Colors.grey,
    this.selectedColor = Colors.blue,
    this.failedColor = Colors.red,
    this.disableColor = Colors.grey,
    this.lineWidth = 2,
    this.solidRadiusRatio = 0.4,
    this.touchRadiusRatio = 0.6,
    this.delayTime = 500,
    this.onCompleted,
  }): super(key: key);
  final GestureState _state = GestureState();

  @override
  State<StatefulWidget> createState() {
    return _state;
  }

  void updateStatus(UnlockStatus status) {
    _state.updateStatus(status);
  }

  static String selectedToString(List<int> rounds) {
    var sb = StringBuffer();
    for (int i = 0; i < rounds.length; i++) {
      sb.write(rounds[i] + 1);
    }
    return sb.toString();
  }
}

class GestureState extends State<GestureUnlockView> {
  UnlockStatus _status = UnlockStatus.normal;

  final List<UnlockPoint> points = List<UnlockPoint>(9);

  final List<UnlockPoint> pathPoints = [];
  UnlockPoint curPoint;
  double _radius;
  double _solidRadius;
  double _touchRadius;
  Timer _timer;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void deactivate() {
    super.deactivate();
    if (_timer?.isActive == true) {
      _timer.cancel();
    }
  }

  void _init() {
    var width = widget.size;
    var roundSpace = widget.roundSpace;
    if (roundSpace != null) {
      _radius = (width - widget.padding * 2 - roundSpace * 2) / 3 / 2;
    } else {
      _radius =
          (width - widget.padding * 2) / (3 + widget.roundSpaceRatio * 2) / 2;
      roundSpace = _radius * 2 * widget.roundSpaceRatio;
    }

    _solidRadius = _radius * widget.solidRadiusRatio;
    _touchRadius = _radius * widget.touchRadiusRatio;

    for (int i = 0; i < points.length; i++) {
      var row = i ~/ 3;
      var column = i % 3;
      var dx = widget.padding + column * (_radius * 2 + roundSpace) + _radius;
      var dy = widget.padding + row * (_radius * 2 + roundSpace) + _radius;
      points[i] = UnlockPoint(x: dx, y: dy, position: i);
    }
  }

  @override
  Widget build(BuildContext context) {
    var enableTouch = _status == UnlockStatus.normal;
    return Stack(
      children: <Widget>[
        Container(
          child: CustomPaint(
            size: Size(widget.size, widget.size),
            painter: UnlockPointPainter(
                type: widget.type,
                points: points,
                radius: _radius,
                solidRadius: _solidRadius,
                lineWidth: widget.lineWidth,
                defaultColor: widget.defaultColor,
                selectedColor: widget.selectedColor,
                failedColor: widget.failedColor,
                disableColor: widget.disableColor),
          ),
        ),
        GestureDetector(
          child: CustomPaint(
            size: Size(widget.size, widget.size),
            painter: UnlockLinePainter(
                pathPoints: this.pathPoints,
                status: _status,
                selectColor: widget.selectedColor,
                failedColor: widget.failedColor,
                lineWidth: widget.lineWidth,
                curPoint: this.curPoint),
          ),
          onPanDown: enableTouch ? this._onPanDown : null,
          onPanUpdate: enableTouch
              ? (DragUpdateDetails e) => this._onPanUpdate(e, context)
              : null,
          onPanEnd: enableTouch
              ? (DragEndDetails e) => this._onPanEnd(e, context)
              : null,
        )
      ],
    );
  }

  void updateStatus(UnlockStatus status) {
    _status = status;
    switch (status) {
      case UnlockStatus.normal:
      case UnlockStatus.disable:
        _updateRoundStatus(status);
        clearAllData();
        break;
      case UnlockStatus.failed:
        for (UnlockPoint round in points) {
          if (round.status == UnlockStatus.success) {
            round.status = UnlockStatus.failed;
          }
        }
        _timer = Timer(Duration(milliseconds: widget.delayTime), () {
          updateStatus(UnlockStatus.normal);
        });
        break;
      case UnlockStatus.success:
        _timer = Timer(Duration(milliseconds: widget.delayTime), () {
          updateStatus(UnlockStatus.normal);
        });
        break;
    }
    setState(() {});
  }

  void _updateRoundStatus(UnlockStatus status) {
    for (UnlockPoint round in points) {
      round.status = status;
    }
  }

  void _onPanDown(DragDownDetails e) {
    this.clearAllData();
//    if (this.onPanDown != null) this.onPanDown();
  }

  void _onPanUpdate(DragUpdateDetails e, BuildContext context) {
    RenderBox box = context.findRenderObject();
    Offset offset = box.globalToLocal(e.globalPosition);
    _slideDealt(offset);
    setState(() {
      curPoint = UnlockPoint(x: offset.dx, y: offset.dy, position: -1);
    });
  }

  void _onPanEnd(DragEndDetails e, BuildContext context) {
    if (pathPoints.length > 0) {
      setState(() {
        curPoint = pathPoints[pathPoints.length - 1];
      });
      if (widget.onCompleted != null) {
        List<int> items = pathPoints.map((item) => item.position).toList();
        widget.onCompleted(items, _status);
      }
//      if (this.immediatelyClear) this._clearAllData(); //clear data
    }
  }

  ///滑动处理
  void _slideDealt(Offset offSet) {
//    print("offset =$offSet");
    int xPosition = -1;
    int yPosition = -1;
    for (int i = 0; i < 3; i++) {
      if (xPosition == -1 &&
          points[i].x + _radius + _touchRadius >= offSet.dx &&
          offSet.dx >= points[i].x - _radius - _touchRadius) {
        xPosition = i;
      }
      if (yPosition == -1 &&
          points[i * 3].y + _radius + _touchRadius >= offSet.dy &&
          offSet.dy >= points[i * 3].y - _radius - _touchRadius) {
        yPosition = i;
      }
    }
    if (xPosition == -1 || yPosition == -1) return;
    int position = yPosition * 3 + xPosition;

    if (points[position].status != UnlockStatus.success) {
      points[position].status = UnlockStatus.success;
      pathPoints.add(points[position]);
    }

//    for (int i = 0; i < points.length; i++) {
//      var round = points[i];
//      if (round.status == UnlockStatus.normal &&
//          round.contains(offSet, _touchRadius)) {
//        round.status = UnlockStatus.success;
//        pathPoints.add(round);
//        break;
//      }
//    }
  }

  clearAllData() {
    for (int i = 0; i < 9; i++) {
      points[i].status = UnlockStatus.normal;
    }
    pathPoints.clear();
    setState(() {});
  }
}
