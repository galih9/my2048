import 'package:flutter/material.dart';
import 'grid-properties.dart';
import 'package:collection/collection.dart';
// import 'tile.dart';

void main() {
  runApp(
    MaterialApp(
      title: '2048',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const TwentyFortyEight(),
    ),
  );
}

class Tile {
  final int x;
  final int y;
  int val;

  Animation<double>? animatedX;
  Animation<double>? animatedY;
  Animation<int>? animatedValue;
  Animation<double>? scale;

  Tile(this.x, this.y, this.val) {
    resetAnimations();
  }

  void resetAnimations() {
    animatedX = AlwaysStoppedAnimation(
      x.toDouble(),
    );
    animatedY = AlwaysStoppedAnimation(
      y.toDouble(),
    );
    animatedValue = AlwaysStoppedAnimation(
      val,
    );
    scale = const AlwaysStoppedAnimation(1.0);
  }

  void moveTo(Animation<double> parent, int x, int y) {
    animatedX = Tween(begin: this.x.toDouble(), end: x.toDouble()).animate(
      CurvedAnimation(
        parent: parent,
        curve: const Interval(
          0.0,
          0.5,
          curve: Curves.easeIn,
        ),
      ),
    );
    animatedY = Tween(begin: this.y.toDouble(), end: y.toDouble()).animate(
      CurvedAnimation(
        parent: parent,
        curve: const Interval(
          0.0,
          0.5,
          curve: Curves.easeIn,
        ),
      ),
    );
  }

  void bounce(Animation<double> parent) {
    scale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.2), weight: 1.0),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 1.0),
    ]).animate(
      CurvedAnimation(
        parent: parent,
        curve: const Interval(
          0.5,
          1.0,
          curve: Curves.easeIn,
        ),
      ),
    );
  }

  void appear(Animation<double> parent) {
    scale = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: parent,
        curve: const Interval(
          0.5,
          1.0,
          curve: Curves.easeIn,
        ),
      ),
    );
  }

  void changeNumber(Animation<double> parent, int newValue) {
    animatedValue = TweenSequence([
      TweenSequenceItem(tween: ConstantTween(val), weight: 0.01),
      TweenSequenceItem(tween: ConstantTween(newValue), weight: 0.99),
    ]).animate(
      CurvedAnimation(
        parent: parent,
        curve: const Interval(0.5, 1.0),
      ),
    );
  }
}

class TwentyFortyEight extends StatefulWidget {
  const TwentyFortyEight({Key? key}) : super(key: key);

  @override
  _TwentyFortyEightState createState() => _TwentyFortyEightState();
}

class _TwentyFortyEightState extends State<TwentyFortyEight>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  List<List<Tile>> grid = List.generate(
    4,
    (y) => List.generate(
      4,
      (x) => Tile(
        x,
        y,
        0,
      ),
    ),
  );
  List<Tile> toAdd = [];
  Iterable<Tile> get flattenedGrid => grid.expand((e) => e);
  Iterable<List<Tile>> get cols => List.generate(
        4,
        (x) => List.generate(
          4,
          (y) => grid[y][x],
        ),
      );

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    controller.addStatusListener(
      (status) {
        if (status == AnimationStatus.completed) {
          for (var element in toAdd) {
            grid[element.y][element.x].val = element.val;
          }
          for (var element in flattenedGrid) {
            element.resetAnimations();
          }
          toAdd.clear();
        }
      },
    );

    grid[1][2].val = 4;
    grid[0][2].val = 4;
    grid[3][2].val = 16;
    grid[0][0].val = 16;

    for (var element in flattenedGrid) {
      element.resetAnimations();
    }
  }

  void addNewTile() {
    List<Tile> empty = flattenedGrid.where((e) => e.val == 0).toList();
    empty.shuffle();
    toAdd.add(Tile(empty.first.x, empty.first.y, 2)..appear(controller));
  }

  @override
  Widget build(BuildContext context) {
    double gridSize = MediaQuery.of(context).size.width - 16.0 * 2;
    double tileSize = (gridSize - 4.0 * 2) / 4;
    List<Widget> stackItems = [];
    stackItems.addAll(
      flattenedGrid.map(
        (e) => Positioned(
          left: e.animatedX!.value * tileSize,
          top: e.animatedY!.value * tileSize,
          width: tileSize,
          height: tileSize,
          child: Center(
            child: Container(
              width: (tileSize - 4.0 * 2) * e.scale!.value,
              height: (tileSize - 4.0 * 2) * e.scale!.value,
              decoration: BoxDecoration(
                color: lightBrown,
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
          ),
        ),
      ),
    );
    stackItems.addAll(
      [flattenedGrid, toAdd].expand((e) => e).map(
            (e) => AnimatedBuilder(
              animation: controller,
              builder: (context, child) => e.animatedValue!.value == 0
                  ? const SizedBox()
                  : Positioned(
                      left: e.x * tileSize,
                      top: e.y * tileSize,
                      width: tileSize,
                      height: tileSize,
                      child: Center(
                        child: Container(
                          width: tileSize - 4.0 * 2,
                          height: tileSize - 4.0 * 2,
                          decoration: BoxDecoration(
                            color: numTileColor[e.animatedValue!.value],
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Center(
                            child: Text(
                              "${e.animatedValue!.value}",
                              style: TextStyle(
                                color: e.animatedValue!.value <= 4
                                    ? greyText
                                    : Colors.white,
                                fontSize: 35,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
          ),
    );

    return Scaffold(
      backgroundColor: tan,
      body: Center(
        child: Container(
          width: gridSize,
          height: gridSize,
          padding: const EdgeInsets.all(4.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8.0),
            color: darkBrown,
          ),
          child: GestureDetector(
            onVerticalDragEnd: (details) => {
              if (details.velocity.pixelsPerSecond.dy < -250 && canSwipeUp())
                {
                  // swipe up
                  doSwipe(swipeUp)
                }
              else if (details.velocity.pixelsPerSecond.dy > 250 &&
                  canSwipeDown())
                {
                  // swipe down
                  doSwipe(swipeDown)
                }
            },
            onHorizontalDragEnd: (details) => {
              if (details.velocity.pixelsPerSecond.dx < -1000 && canSwipeLeft())
                {
                  // swipe left
                  doSwipe(swipeLeft)
                }
              else if (details.velocity.pixelsPerSecond.dx > 1000 &&
                  canSwipeRight())
                {
                  // swipe right
                  doSwipe(swipeRight)
                }
            },
            child: Stack(
              children: stackItems,
            ),
          ),
        ),
      ),
    );
  }

  void doSwipe(void Function() swipeFn) {
    setState(() {
      swipeFn();
      addNewTile();
      controller.forward(from: 0);
    });
  }

  bool canSwipeRight() => grid.any(canSwipe);
  bool canSwipeLeft() => grid.map((e) => e.reversed.toList()).any(canSwipe);

  bool canSwipeUp() => cols.any(canSwipe);
  bool canSwipeDown() => cols.map((e) => e.reversed.toList()).any(canSwipe);

  bool canSwipe(List<Tile> tiles) {
    for (var i = 0; i < tiles.length; i++) {
      if (tiles[i].val == 0) {
        if (tiles.skip(i + 1).any((e) => e.val != 0)) {
          return true;
        } else {
          Tile? nonZeroTile =
              tiles.skip(i + 1).firstWhereOrNull((e) => e.val != 0);
          if (nonZeroTile?.val == tiles[i].val) {
            return true;
          }
        }
      }
    }
    return false;
  }

  void swipeLeft() => grid.forEach(mergeTiles);
  void swipeRight() => grid.map((e) => e.reversed.toList()).forEach(mergeTiles);

  void swipeUp() => cols.forEach(mergeTiles);
  void swipeDown() => cols.map((e) => e.reversed.toList()).forEach(mergeTiles);

  void mergeTiles(List<Tile> tiles) {
    for (var i = 0; i < tiles.length; i++) {
      Iterable<Tile> toCheck =
          tiles.skip(i).skipWhile((value) => value.val == 0);
      if (toCheck.isNotEmpty) {
        Tile t = toCheck.first;
        Tile? merge = toCheck.skip(1).firstWhereOrNull((t) => t.val != 0);
        if (merge?.val != t.val) {
          merge = null;
        }
        if (tiles[i] != t || merge != null) {
          int resultValue = t.val;
          t.moveTo(controller, tiles[i].x, tiles[i].y);
          if (merge != null) {
            resultValue += merge.val;
            merge.moveTo(controller, tiles[i].x, tiles[i].y);
            merge.bounce(controller);
            merge.changeNumber(controller, resultValue);
            merge.val = 0;
            t.changeNumber(controller, 0);
          }
          t.val = 0;
          tiles[i].val = resultValue;
        }
      }
    }
  }
}
