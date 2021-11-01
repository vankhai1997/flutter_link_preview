library flutter_link_preview;

import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'package:flutter/material.dart' as ui;
import 'package:gbk2utf8/gbk2utf8.dart';
import 'package:html/dom.dart' as prefix hide Text;
import 'package:html/dom.dart';
import 'package:html/parser.dart' as parser;
import 'package:http/http.dart';
import 'package:http/io_client.dart';

part 'web_analyzer.dart';

/// Link Preview Widget
class FlutterLinkPreview extends ui.StatefulWidget {
  const FlutterLinkPreview({
    ui.Key? key,
    required this.url,
    this.cache = const Duration(hours: 24),
    this.builder,
    this.titleStyle,
    this.bodyStyle,
    this.showMultimedia = true,
    this.useMultithread = false,
  }) : super(key: key);

  /// Web address, HTTP and HTTPS support
  final String url;

  /// Cache result time, default cache 1 hour
  final Duration cache;

  /// Customized rendering methods
  final ui.Widget Function(InfoBase info)? builder;

  /// Title style
  final ui.TextStyle? titleStyle;

  /// Content style
  final ui.TextStyle? bodyStyle;

  /// Show image or video
  final bool showMultimedia;

  /// Whether to use multi-threaded analysis of web pages
  final bool useMultithread;

  @override
  _FlutterLinkPreviewState createState() => _FlutterLinkPreviewState();
}

class _FlutterLinkPreviewState extends ui.State<FlutterLinkPreview> {
  late String _url;
  InfoBase? _info;

  @override
  void initState() {
    _url = widget.url.trim();
    _info = WebAnalyzer.getInfoFromCache(_url);
    if (_info == null) _getInfo();
    super.initState();
  }

  Future<void> _getInfo() async {
    if (_url.startsWith("http")) {
      _info = await WebAnalyzer.getInfo(
        _url,
        cache: widget.cache,
        multimedia: widget.showMultimedia,
        useMultithread: widget.useMultithread,
      );
      if (mounted) setState(() {});
    } else {
      print("Links don't start with http or https from : $_url");
    }
  }

  @override
  ui.Widget build(ui.BuildContext context) {
    if (widget.builder != null && _info != null) {
      return widget.builder!(_info!);
    }

    if (_info == null) return const ui.SizedBox();

    if (_info is WebImageInfo) {
      return ui.Image.network(
        (_info as WebImageInfo).image ?? "",
        fit: ui.BoxFit.contain,
      );
    }

    final WebInfo? info = _info! as WebInfo?;
    if (!WebAnalyzer.isNotEmpty(info?.title ?? "")) return const ui.SizedBox();
    return ui.Column(
      crossAxisAlignment: ui.CrossAxisAlignment.start,
      children: <ui.Widget>[
        ui.Row(
          children: [
            ui.Image.network(
              info?.icon ?? "",
              fit: ui.BoxFit.contain,
              width: 30,
              height: 30,
              errorBuilder: (context, error, stackTrace) => ui.Icon(
                  ui.Icons.link,
                  size: 30,
                  color: widget.titleStyle?.color),
            ),
            const ui.SizedBox(width: 8),
            ui.Expanded(
              child: ui.Text(
                info?.title ?? "",
                maxLines: 1,
                overflow: ui.TextOverflow.ellipsis,
                style: widget.titleStyle,
              ),
            ),
          ],
        ),
        if (WebAnalyzer.isNotEmpty(info?.description ?? "")) ...[
          const ui.SizedBox(height: 8),
          ui.Text(
            info?.description ?? "",
            maxLines: 5,
            overflow: ui.TextOverflow.ellipsis,
            style: widget.bodyStyle,
          ),
        ],
      ],
    );
  }
}
