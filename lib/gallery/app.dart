// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart' show timeDilation;

import 'package:url_launcher/url_launcher.dart';

import 'demos.dart';
import 'home.dart';
import 'options.dart';
import 'scales.dart';
import 'themes.dart';
import 'updater.dart';

class GalleryApp extends StatefulWidget {
  const GalleryApp({
    Key key,
    this.updateUrlFetcher,
    this.enablePerformanceOverlay = true,
    this.enableRasterCacheImagesCheckerboard = true,
    this.enableOffscreenLayersCheckerboard = true,
    this.onSendFeedback,
    this.testMode = false,
  }) : super(key: key);

  final UpdateUrlFetcher updateUrlFetcher;
  final bool enablePerformanceOverlay;
  final bool enableRasterCacheImagesCheckerboard;
  final bool enableOffscreenLayersCheckerboard;
  final VoidCallback onSendFeedback;
  final bool testMode;

  @override
  _GalleryAppState createState() => new _GalleryAppState();
}

class _GalleryAppState extends State<GalleryApp> {
  GalleryOptions _options;
  Timer _timeDilationTimer;

  Map<String, WidgetBuilder> _buildRoutes() {
    // For a different example of how to set up an application routing table
    // using named routes, consider the example in the Navigator class documentation:
    // https://docs.flutter.io/flutter/widgets/Navigator-class.html
    return new Map<String, WidgetBuilder>.fromIterable(
      kAllGalleryDemos,
      key: (dynamic demo) => '${demo.routeName}',
      value: (dynamic demo) => demo.buildRoute,
    );
  }

  @override
  void initState() {
    super.initState();
    _options = new GalleryOptions(
      theme: kLightGalleryTheme,
      textScaleFactor: kAllGalleryTextScaleValues[0],
      timeDilation: timeDilation,
      platform: defaultTargetPlatform,
    );
  }

  @override
  void dispose() {
    _timeDilationTimer?.cancel();
    _timeDilationTimer = null;
    super.dispose();
  }

  void _handleOptionsChanged(GalleryOptions newOptions) {
    setState(() {
      if (_options.timeDilation != newOptions.timeDilation) {
        _timeDilationTimer?.cancel();
        _timeDilationTimer = null;
        if (newOptions.timeDilation > 1.0) {
          // We delay the time dilation change long enough that the user can see
          // that UI has started reacting and then we slam on the brakes so that
          // they see that the time is in fact now dilated.
          _timeDilationTimer = new Timer(const Duration(milliseconds: 150), () {
            timeDilation = newOptions.timeDilation;
          });
        } else {
          timeDilation = newOptions.timeDilation;
        }
      }

      _options = newOptions;
    });
  }

  Widget _applyTextScaleFactor(Widget child) {
    return new Builder(
      builder: (BuildContext context) {
        return new MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaleFactor: _options.textScaleFactor.scale,
          ),
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget home = new GalleryHome(
      testMode: widget.testMode,
      optionsPage: new GalleryOptionsPage(
        options: _options,
        onOptionsChanged: _handleOptionsChanged,
        onSendFeedback: widget.onSendFeedback ?? () {
          launch('https://github.com/flutter/flutter/issues/new', forceSafariVC: false);
        },
      ),
    );

    if (widget.updateUrlFetcher != null) {
      home = new Updater(
        updateUrlFetcher: widget.updateUrlFetcher,
        child: home,
      );
    }

    return new MaterialApp(
      theme: _options.theme.data.copyWith(platform: _options.platform),
      title: 'Flutter Gallery',
      color: Colors.grey,
      showPerformanceOverlay: _options.showPerformanceOverlay,
      checkerboardOffscreenLayers: _options.showOffscreenLayersCheckerboard,
      checkerboardRasterCacheImages: _options.showRasterCacheImagesCheckerboard,
      routes: _buildRoutes(),
      builder: (BuildContext context, Widget child) {
        return new Directionality(
          textDirection: _options.textDirection,
          child: _applyTextScaleFactor(child),
        );
      },
      home: home,
    );
  }
}

/*
************************************************
Trying To Call Reorderable List directly
************************************************
*/

enum _ReorderableListType {
  /// A list tile that contains a [CircleAvatar].
  horizontalAvatar,

  /// A list tile that contains a [CircleAvatar].
  verticalAvatar,

  /// A list tile that contains three lines of text and a checkbox.
  threeLine,
}

class ReorderableListDemo extends StatefulWidget {
  const ReorderableListDemo({ Key key }) : super(key: key);

  static const String routeName = '/material/reorderable-list';

  @override
  _ListDemoState createState() => new _ListDemoState();
}

class _ListItem {
  _ListItem(this.value, this.checkState);

  final String value;

  bool checkState;
}

class _ListDemoState extends State<ReorderableListDemo> {
  static final GlobalKey<ScaffoldState> scaffoldKey = new GlobalKey<ScaffoldState>();

  PersistentBottomSheetController<Null> _bottomSheet;
  _ReorderableListType _itemType = _ReorderableListType.threeLine;
  bool _reverseSort = false;
  final List<_ListItem> _items = <String>[
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N',
  ].map((String item) => new _ListItem(item, false)).toList();

  void changeItemType(_ReorderableListType type) {
    setState(() {
      _itemType = type;
    });
    // Rebuild the bottom sheet to reflect the selected list view.
    _bottomSheet?.setState(() { });
    // Close the bottom sheet to give the user a clear view of the list.
    _bottomSheet?.close();
  }

  void _showConfigurationSheet() {
    setState(() {
      _bottomSheet = scaffoldKey.currentState.showBottomSheet((BuildContext bottomSheetContext) {
        return new DecoratedBox(
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: Colors.black26)),
          ),
          child: new ListView(
            shrinkWrap: true,
            primary: false,
            children: <Widget>[
              new RadioListTile<_ReorderableListType>(
                dense: true,
                title: const Text('Horizontal Avatars'),
                value: _ReorderableListType.horizontalAvatar,
                groupValue: _itemType,
                onChanged: changeItemType,
              ),
              new RadioListTile<_ReorderableListType>(
                dense: true,
                title: const Text('Vertical Avatars'),
                value: _ReorderableListType.verticalAvatar,
                groupValue: _itemType,
                onChanged: changeItemType,
              ),
              new RadioListTile<_ReorderableListType>(
                dense: true,
                title: const Text('Three-line'),
                value: _ReorderableListType.threeLine,
                groupValue: _itemType,
                onChanged: changeItemType,
              ),
            ],
          ),
        );
      });

      // Garbage collect the bottom sheet when it closes.
      _bottomSheet.closed.whenComplete(() {
        if (mounted) {
          setState(() {
            _bottomSheet = null;
          });
        }
      });
    });
  }

  Widget buildListTile(_ListItem item) {
    const Widget secondary = Text(
      'Even more additional list item information appears on line three.',
    );
    Widget listTile;
    switch (_itemType) {
      case _ReorderableListType.threeLine:
        listTile = new CheckboxListTile(
          key: new Key(item.value),
          isThreeLine: true,
          value: item.checkState ?? false,
          onChanged: (bool newValue) {
            setState(() {
              item.checkState = newValue;
            });
          },
          title: new Text('This item represents ${item.value}.'),
          subtitle: secondary,
          secondary: const Icon(Icons.drag_handle),
        );
        break;
      case _ReorderableListType.horizontalAvatar:
      case _ReorderableListType.verticalAvatar:
        listTile = new Container(
          key: new Key(item.value),
          height: 100.0,
          width: 100.0,
          child: new CircleAvatar(child: new Text(item.value),
            backgroundColor: Colors.green,
          ),
        );
        break;
    }

    return listTile;
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final _ListItem item = _items.removeAt(oldIndex);
      _items.insert(newIndex, item);
    });
  }


  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      key: scaffoldKey,
      appBar: new AppBar(
        title: const Text('Reorderable list'),
        actions: <Widget>[
          new IconButton(
            icon: const Icon(Icons.sort_by_alpha),
            tooltip: 'Sort',
            onPressed: () {
              setState(() {
                _reverseSort = !_reverseSort;
                _items.sort((_ListItem a, _ListItem b) => _reverseSort ? b.value.compareTo(a.value) : a.value.compareTo(b.value));
              });
            },
          ),
          new IconButton(
            icon: new Icon(
              Theme.of(context).platform == TargetPlatform.iOS
                  ? Icons.more_horiz
                  : Icons.more_vert,
            ),
            tooltip: 'Show menu',
            onPressed: _bottomSheet == null ? _showConfigurationSheet : null,
          ),
        ],
      ),
      body: new Scrollbar(
        child: new ReorderableListView(
          header: _itemType != _ReorderableListType.threeLine
              ? new Padding(
              padding: const EdgeInsets.all(8.0),
              child: new Text('Header of the list', style: Theme.of(context).textTheme.headline))
              : null,
          onReorder: _onReorder,
          scrollDirection: _itemType == _ReorderableListType.horizontalAvatar ? Axis.horizontal : Axis.vertical,
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          children: _items.map(buildListTile).toList(),
        ),
      ),
    );
  }
}

/*
************************************************
Trying To Call MyApp Demo
************************************************
*/


class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Samave Events',
      theme: new ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or press Run > Flutter Hot Reload in IntelliJ). Notice that the
        // counter didn't reset back to zero; the application is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: new MyHomePage(title: 'Samave Events Home'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyListDemoState createState() => new _MyListDemoState();
  //_MyHomePageState createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.

    return new Scaffold(
      appBar: new AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: new Text(widget.title),
      ),
      body: new Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: new Column(
          // Column is also layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Invoke "debug paint" (press "p" in the console where you ran
          // "flutter run", or select "Toggle Debug Paint" from the Flutter tool
          // window in IntelliJ) to see the wireframe for each widget.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            new Text(
              'You have pushed the button this many times:',
            ),
            new Text(
              '$_counter',
              style: Theme.of(context).textTheme.display1,
            ),
          ],
        ),
      ),
      floatingActionButton: new FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: new Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

// ***************************

class _MyListDemoState extends State<MyHomePage> {
  static final GlobalKey<ScaffoldState> scaffoldKey = new GlobalKey<ScaffoldState>();

  PersistentBottomSheetController<Null> _bottomSheet;
  _ReorderableListType _itemType = _ReorderableListType.threeLine;
  bool _reverseSort = false;
  final List<_ListItem> _items = <String>[
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N',
  ].map((String item) => new _ListItem('Event '+item, false)).toList();

  void changeItemType(_ReorderableListType type) {
    setState(() {
      _itemType = type;
    });
    // Rebuild the bottom sheet to reflect the selected list view.
    _bottomSheet?.setState(() { });
    // Close the bottom sheet to give the user a clear view of the list.
    _bottomSheet?.close();
  }

  void _showConfigurationSheet() {
    setState(() {
      _bottomSheet = scaffoldKey.currentState.showBottomSheet((BuildContext bottomSheetContext) {
        return new DecoratedBox(
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: Colors.black26)),
          ),
          child: new ListView(
            shrinkWrap: true,
            primary: false,
            children: <Widget>[
              new RadioListTile<_ReorderableListType>(
                dense: true,
                title: const Text('Horizontal Avatars'),
                value: _ReorderableListType.horizontalAvatar,
                groupValue: _itemType,
                onChanged: changeItemType,
              ),
              new RadioListTile<_ReorderableListType>(
                dense: true,
                title: const Text('Vertical Avatars'),
                value: _ReorderableListType.verticalAvatar,
                groupValue: _itemType,
                onChanged: changeItemType,
              ),
              new RadioListTile<_ReorderableListType>(
                dense: true,
                title: const Text('Three-line'),
                value: _ReorderableListType.threeLine,
                groupValue: _itemType,
                onChanged: changeItemType,
              ),
            ],
          ),
        );
      });

      // Garbage collect the bottom sheet when it closes.
      _bottomSheet.closed.whenComplete(() {
        if (mounted) {
          setState(() {
            _bottomSheet = null;
          });
        }
      });
    });
  }

  Widget buildListTile(_ListItem item) {
    const Widget secondary = Text(
      'Even more additional list item information appears on line three.',
    );
    Widget listTile;
    switch (_itemType) {
      case _ReorderableListType.threeLine:
        //listTile = new GridTile() ;
        listTile = //const Icon(Icons.drag_handle),
        ///*
        new CheckboxListTile(
          key: new Key(item.value),
          isThreeLine: true,
          value: item.checkState ?? false,
          onChanged: (bool newValue) {
            setState(() {
              item.checkState = newValue;
            });
          },
        //*/
        /*
        new ListTile(
          key: new Key(item.value),
          isThreeLine: true,
          leading: new Text('a'),
        */
          title: new Text('This item represents ${item.value}.'),
          /*new Row(
            children: [
              new Text('This item represents ${item.value}.'),
              new Text('T'),
            ],
          ),*/

          subtitle: secondary,

          secondary: //const Icon(Icons.drag_handle),
            new Column(
              children: [
                new Text('07:00'),

                new Text('08:30'),
              ],
            ),

        );
        break;
      case _ReorderableListType.horizontalAvatar:
      case _ReorderableListType.verticalAvatar:
        listTile = new Container(
          key: new Key(item.value),
          height: 100.0,
          width: 100.0,
          child: new CircleAvatar(child: new Text(item.value),
            backgroundColor: Colors.green,
          ),
        );
        break;
    }

    return listTile;
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final _ListItem item = _items.removeAt(oldIndex);
      _items.insert(newIndex, item);
    });
  }


  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      key: scaffoldKey,
      appBar: new AppBar(
        title: const Text('Samave Events Home'),
        actions: <Widget>[
          new IconButton(
            icon: const Icon(Icons.sort_by_alpha),
            tooltip: 'Sort',
            onPressed: () {
              setState(() {
                _reverseSort = !_reverseSort;
                _items.sort((_ListItem a, _ListItem b) => _reverseSort ? b.value.compareTo(a.value) : a.value.compareTo(b.value));
              });
            },
          ),
          new IconButton(
            icon: new Icon(
              Theme.of(context).platform == TargetPlatform.iOS
                  ? Icons.more_horiz
                  : Icons.more_vert,
            ),
            tooltip: 'Show menu',
            onPressed: _bottomSheet == null ? _showConfigurationSheet : null,
          ),
        ],
      ),
      body: new Scrollbar(
        child: new ReorderableListView(
          header: _itemType != _ReorderableListType.threeLine
              ? new Padding(
              padding: const EdgeInsets.all(8.0),
              child: new Text('List of Events', style: Theme.of(context).textTheme.headline))
              : null,
          onReorder: _onReorder,
          scrollDirection: _itemType == _ReorderableListType.horizontalAvatar ? Axis.horizontal : Axis.vertical,
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          children: _items.map(buildListTile).toList(),
        ),
      ),
    );
  }
}
