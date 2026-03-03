import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

void main() {
  runApp(const ReadingDynamicApp());
}

class ReadingDynamicApp extends StatelessWidget {
  const ReadingDynamicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Reading Dynamic Island',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF0E7D8E),
      ),
      home: const ReadingScreen(),
    );
  }
}

class ReadingScreen extends StatefulWidget {
  const ReadingScreen({super.key});

  @override
  State<ReadingScreen> createState() => _ReadingScreenState();
}

class _ReadingScreenState extends State<ReadingScreen>
    with WidgetsBindingObserver {
  final ScrollController _scrollController = ScrollController();
  final _liveActivity = const NativeLiveActivityBridge();
  static const double _nativeProgressThreshold = 0.003;
  static const int _nativeMinUpdateMs = 80;
  double _progress = 0;
  int _chapter = 1;
  double _lastSentProgress = -1;
  int _lastSentChapter = -1;
  DateTime _lastSentAt = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _liveActivity.start(
        title: 'Reading Dynamic',
        chapter: 'Chapter $_chapter',
        progress: 0,
      );
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients) {
      return;
    }

    final maxScroll = _scrollController.position.maxScrollExtent;
    if (maxScroll <= 0) {
      setState(() => _progress = 0);
      return;
    }

    final nextProgress = (_scrollController.offset / maxScroll).clamp(0.0, 1.0);
    final nextChapter = ((nextProgress * _sections.length).floor() + 1).clamp(
      1,
      _sections.length,
    );
    if ((nextProgress - _progress).abs() > 0.001) {
      setState(() {
        _progress = nextProgress;
        _chapter = nextChapter;
      });
      _sendNativeProgress(nextProgress);
    }
  }

  void _sendNativeProgress(double progress) {
    final now = DateTime.now();
    final changedEnough =
        (progress - _lastSentProgress).abs() >= _nativeProgressThreshold;
    final chapterChanged = _chapter != _lastSentChapter;
    final timeElapsed =
        now.difference(_lastSentAt).inMilliseconds >= _nativeMinUpdateMs;
    if (!changedEnough && !chapterChanged && !timeElapsed) {
      return;
    }

    _lastSentProgress = progress;
    _lastSentChapter = _chapter;
    _lastSentAt = now;
    _liveActivity.update(chapter: 'Chapter $_chapter', progress: progress);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _liveActivity.update(chapter: 'Chapter $_chapter', progress: _progress);
    }
  }

  @override
  void dispose() {
    _liveActivity.end();
    WidgetsBinding.instance.removeObserver(this);
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    final isIOS = !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
    final islandTop = isIOS
        ? (topInset > 44 ? 11.0 : topInset + 6)
        : topInset + 8;
    final contentTopPadding = topInset + 78;

    return Scaffold(
      body: Stack(
        children: [
          ListView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(20, contentTopPadding, 20, 32),
            children: [
              _ReadingHeader(progress: _progress),
              const SizedBox(height: 24),
              ..._sections.map(
                (section) =>
                    _ReadingSection(title: section.title, body: section.body),
              ),
            ],
          ),
          Positioned(
            top: islandTop,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Center(child: DynamicIslandProgress(progress: _progress)),
            ),
          ),
        ],
      ),
    );
  }
}

class DynamicIslandProgress extends StatelessWidget {
  const DynamicIslandProgress({required this.progress, super.key});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: progress),
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      builder: (context, value, _) {
        return SizedBox(
          width: 132,
          height: 42,
          child: CustomPaint(
            painter: _IslandProgressPainter(progress: value),
            child: Container(
              margin: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _IslandProgressPainter extends CustomPainter {
  _IslandProgressPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final rRect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(size.height / 2),
    );

    final basePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.1
      ..color = const Color(0xFF77F6E9).withValues(alpha: 0.2);

    canvas.drawRRect(rRect, basePaint);

    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3)
      ..color = const Color(
        0xFF63F8E8,
      ).withValues(alpha: 0.3 + (0.3 * progress));

    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF5DFFF0);

    final path = Path()..addRRect(rRect);
    final metric = path.computeMetrics().first;
    final drawLength = metric.length * progress;

    if (drawLength > 0) {
      final drawPath = metric.extractPath(0, drawLength);
      canvas.drawPath(drawPath, glowPaint);
      canvas.drawPath(drawPath, strokePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _IslandProgressPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _ReadingHeader extends StatelessWidget {
  const _ReadingHeader({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Read',
            style: TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Scroll to see the island ring fill around the pill.',
            style: TextStyle(
              color: Color(0xFFD3F9F4),
              fontSize: 14,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: progress,
              backgroundColor: Colors.black.withValues(alpha: 0.18),
              valueColor: const AlwaysStoppedAnimation(Color(0xFF72FFF1)),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${(progress * 100).round()}% read',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadingSection extends StatelessWidget {
  const _ReadingSection({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              body,
              style: const TextStyle(
                color: Color(0xFFE6FFFB),
                fontSize: 15,
                height: 1.55,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionData {
  const _SectionData({required this.title, required this.body});

  final String title;
  final String body;
}

final List<_SectionData> _sections = List.generate(12, (index) {
  final section = index + 1;
  final lines = List.generate(
    4 + (index % 3),
    (line) =>
        'Section $section line ${line + 1}: ${_sentences[(index + line) % _sentences.length]}',
  );

  return _SectionData(title: 'Chapter $section', body: lines.join('\n\n'));
});

const List<String> _sentences = [
  'Design is not decoration; it is how attention flows through a page.',
  'When movement has purpose, even small transitions feel alive.',
  'Progress indicators work best when they are calm, clear, and consistent.',
  'Readable spacing helps the eye move without losing context.',
  'Subtle contrast can separate structure from content without heavy borders.',
  'A good reading surface fades away and lets the story lead.',
];

class NativeLiveActivityBridge {
  const NativeLiveActivityBridge();

  static const MethodChannel _channel = MethodChannel(
    'reading_dynamic/live_activity',
  );

  bool get _isIOS => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  Future<void> start({
    required String title,
    required String chapter,
    required double progress,
  }) async {
    if (!_isIOS) return;
    try {
      await _channel.invokeMethod<bool>('start', {
        'title': title,
        'chapter': chapter,
        'progress': progress.clamp(0.0, 1.0),
      });
    } on PlatformException {
      // Ignore when Live Activities are unavailable on this device/version.
    }
  }

  Future<void> update({
    required String chapter,
    required double progress,
  }) async {
    if (!_isIOS) return;
    try {
      await _channel.invokeMethod<bool>('update', {
        'chapter': chapter,
        'progress': progress.clamp(0.0, 1.0),
      });
    } on PlatformException {
      // Ignore when no activity is running or unavailable.
    }
  }

  Future<void> end() async {
    if (!_isIOS) return;
    try {
      await _channel.invokeMethod<bool>('end');
    } on PlatformException {
      // Ignore when no activity is running.
    }
  }
}
