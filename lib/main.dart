import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  double visibleExtent = 100.0;

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Scaffold(
        floatingActionButton: ElevatedButton(
          onPressed: () {
            setState(() {
              if (visibleExtent <= 100) {
                visibleExtent = 120;
              } else {
                visibleExtent = 100;
              }
            });
          },
          child: Text("修改高度"),
        ),
        body: CustomScrollView(
          slivers: [
            CupertinoSliverNavigationBar(
              largeTitle: Text("app"),
            ),
            // CupertinoSliverRefreshControl(
            //
            // ),
            SliverToBoxAdapter(
              child: Container(
                height: 50,
                color: Colors.green,
                child: Center(child: Text("hi")),
              ),
            ),
            SliverFlexibleHeader(
              visibleExtent: 50,
              builder: (BuildContext context, double maxExtent) {
                return Container(
                  // height: maxExtent,
                  height: 50,
                  color: Colors.blue,
                  child: Text("hello:"),
                );
              },
            ),
            // SliverFlexibleHeader(
            //   visibleExtent: visibleExtent,
            //   builder: (BuildContext context, double maxExtent) {
            //     return Container(
            //       height: maxExtent,
            //       color: Colors.blue,
            //       child: Text("hello:${maxExtent}"),
            //     );
            //   },
            // ),
            SliverList.separated(
              itemBuilder: (context, index) {
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  color: Colors.grey,
                  child: Text("内容：${index}",
                      textScaler: const TextScaler.linear(2)),
                );
              },
              itemCount: 30,
              separatorBuilder: (BuildContext context, int index) {
                return const Divider(
                  height: 1,
                );
              },
            )
          ],
        ),
      ),
    );
  }
}

typedef SliverFlexibleHeaderBuilder = Widget Function(
  BuildContext context,
  double maxExtent,
);

class SliverFlexibleHeader extends StatelessWidget {
  final double visibleExtent;
  final SliverFlexibleHeaderBuilder builder;

  const SliverFlexibleHeader({
    super.key,
    this.visibleExtent = 0,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return _SliverFlexibleHeader(
      visibleExtent: visibleExtent,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return builder(context, constraints.maxHeight);
        },
      ),
    );
  }
}

class _SliverFlexibleHeader extends SingleChildRenderObjectWidget {
  final double visibleExtent;

  const _SliverFlexibleHeader(
      {super.key, required Widget child, required this.visibleExtent})
      : super(child: child);

  @override
  RenderObject createRenderObject(BuildContext context) {
    return FlexibleHeaderRenderSliver(visibleExtent);
  }

  @override
  void updateRenderObject(
      BuildContext context, FlexibleHeaderRenderSliver renderObject) {
    renderObject.visibleExtent = visibleExtent;
  }
}

class FlexibleHeaderRenderSliver extends RenderSliverSingleBoxAdapter {
  late double _visibleExtent;

  FlexibleHeaderRenderSliver(visibleExtent) : _visibleExtent = visibleExtent;

  double? _scrollOffsetCorrection; //修正高度差值
  bool _reported = false;

  set visibleExtent(double value) {
    if (_visibleExtent != value) {
      _reported = false;
      _scrollOffsetCorrection = value - _visibleExtent;
      _visibleExtent = value;
      markNeedsLayout();
    }
  }

  @override
  void performLayout() {
    if (child == null) {
      geometry = SliverGeometry.zero;
      return;
    }

    child!.layout(
        constraints.asBoxConstraints(
          maxExtent: constraints.remainingPaintExtent,
        ),
        parentUsesSize: true);

    final childExtent = child!.size.height;

    final paintedChildSize =
        calculatePaintOffset(constraints, from: 0.0, to: childExtent);
    print("${constraints.overlap} ${constraints.scrollOffset} ${paintedChildSize}");
    geometry = SliverGeometry(
      scrollExtent: childExtent,
      paintOrigin: constraints.overlap,
      paintExtent: childExtent,
      maxPaintExtent: childExtent,
      layoutExtent: paintedChildSize,
    );
  }

// @override
// void performLayout() {
//   if (_scrollOffsetCorrection != null) {
//     geometry = SliverGeometry(
//       scrollExtent: _visibleExtent,
//       scrollOffsetCorrection: _scrollOffsetCorrection,
//     );
//     _scrollOffsetCorrection = null;
//     return;
//   }
//
//   //滑动距离大于_visibleExtent(自身高度)，则表示节点已经在屏幕之外
//   if (child == null || (constraints.scrollOffset > _visibleExtent)) {
//     geometry = SliverGeometry(
//       scrollExtent: _visibleExtent,
//     );
//     if (!_reported) {
//       _reported = true;
//       child!.layout(
//         constraints.asBoxConstraints(maxExtent: 0),
//         parentUsesSize: false,
//       );
//     }
//     return;
//   }
//   _reported = false;
//   //1. 下拉超出边界，scrollOffset会一直为0，overlap为负
//   //2. 上拉超出边界，scrollOffset为正数，overlap为0
//
//   final overScroll =
//       constraints.overlap < 0.0 ? constraints.overlap.abs() : 0.0;
//
//   //绘制区域 = 节点高度 + 下拉滑动距离.abs - 向上滚动距离
//   var paintExtent = _visibleExtent + overScroll - constraints.scrollOffset;
//   //最大绘制高度不能大于最大绘制高度，也就是viewport高度
//   paintExtent = min(paintExtent, constraints.remainingPaintExtent);
//
//   child!.layout(
//     constraints.asBoxConstraints(maxExtent: paintExtent),
//     parentUsesSize: true,
//   );
//
//   final layoutExtent = min(_visibleExtent, paintExtent);
//
//   geometry = SliverGeometry(
//     scrollExtent: _visibleExtent,
//     //从哪个地方开始绘制
//     paintOrigin: -overScroll,
//     paintExtent: paintExtent,
//     maxPaintExtent: paintExtent,
//     layoutExtent: layoutExtent,
//   );
// }
// @override
// double childMainAxisPosition(covariant RenderBox child) => 0.0;
}
