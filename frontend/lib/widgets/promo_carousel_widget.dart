// lib/widgets/promo_carousel_widget.dart
//
// Carousel publicitaire réutilisable.
// Accepte une liste d'AdModel et les affiche en carousel animé.
// Supporte les types texte, image et YouTube.

import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../models/ad_model.dart';

class PromoCarouselWidget extends StatefulWidget {
  final List<AdModel> ads;
  final bool isDesktop;

  const PromoCarouselWidget({
    Key? key,
    required this.ads,
    this.isDesktop = false,
  }) : super(key: key);

  @override
  State<PromoCarouselWidget> createState() => _PromoCarouselWidgetState();
}

class _PromoCarouselWidgetState extends State<PromoCarouselWidget>
    with WidgetsBindingObserver {
  int _index = 0;
  Timer? _timer;
  bool _youtubeDismissed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      final ads = widget.ads;
      if (ads.isEmpty) return;
      final current = ads[_index % ads.length];
      // Don't auto-advance while a YouTube ad is playing
      if (current.adType == AdModel.typeYoutube) return;
      setState(() => _index = (_index + 1) % ads.length);
    });
  }

  void _advanceToNext() {
    if (!mounted) return;
    final ads = widget.ads;
    if (ads.isEmpty) return;
    setState(() {
      _index = (_index + 1) % ads.length;
      _youtubeDismissed = false;
    });
  }

  void _dismissYoutubeAd() {
    if (!mounted) return;
    setState(() => _youtubeDismissed = true);
  }

  void _prevSlide() {
    if (!mounted) return;
    final ads = widget.ads;
    if (ads.isEmpty) return;
    setState(() {
      _index = (_index - 1 + ads.length) % ads.length;
      _youtubeDismissed = false;
    });
  }

  @override
  void didUpdateWidget(PromoCarouselWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ads != widget.ads) {
      // Reset index if ads list changed
      if (widget.ads.isNotEmpty) {
        _index = _index % widget.ads.length;
      } else {
        _index = 0;
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _timer?.cancel();
    } else if (state == AppLifecycleState.resumed) {
      _startTimer();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  // ── Dot indicators ─────────────────────────────────────────────────────────
  Widget _buildDots(int safeIndex, int total) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        total,
        (i) => GestureDetector(
          onTap: () => setState(() => _index = i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.symmetric(vertical: 3),
            width: safeIndex == i ? 18 : 6,
            height: 6,
            decoration: BoxDecoration(
              color:
                  Colors.white.withValues(alpha: safeIndex == i ? 0.95 : 0.38),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
      ),
    );
  }

  // ── Text ad ─────────────────────────────────────────────────────────────────
  Widget _buildTextContent(
      AdModel ad, int safeIndex, int total, bool isDark, Color textPrimary, Color textMuted) {
    final p = widget.isDesktop ? 22.0 : 18.0;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(p),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: isDark
              ? [
                  ad.color.withValues(alpha: 0.22),
                  ad.colorEnd.withValues(alpha: 0.14),
                ]
              : [
                  ad.color.withValues(alpha: 0.9),
                  ad.colorEnd,
                ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Row(
        children: [
          Text(ad.emoji,
              style: TextStyle(fontSize: widget.isDesktop ? 32 : 26)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ad.title,
                  style: TextStyle(
                    color: isDark ? textPrimary : Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: widget.isDesktop ? 15 : 13,
                  ),
                ),
                if (ad.subtitle.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    ad.subtitle,
                    style: TextStyle(
                      color: isDark
                          ? textMuted
                          : Colors.white.withValues(alpha: 0.82),
                      fontWeight: FontWeight.w400,
                      fontSize: widget.isDesktop ? 13 : 11,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          _buildDots(safeIndex, total),
        ],
      ),
    );
  }

  // ── Image ad ─────────────────────────────────────────────────────────────────
  Widget _buildImageContent(AdModel ad, int safeIndex, int total) {
    final p = widget.isDesktop ? 22.0 : 18.0;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: 16 / 7,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: ad.imageUrl!,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      ad.color.withValues(alpha: 0.5),
                      ad.colorEnd.withValues(alpha: 0.3),
                    ],
                  ),
                ),
              ),
              errorWidget: (_, __, ___) => Container(
                color: ad.color.withValues(alpha: 0.3),
                child: Center(
                  child: Text(ad.emoji, style: const TextStyle(fontSize: 40)),
                ),
              ),
            ),
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Colors.black87],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(p),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              ad.title,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: widget.isDesktop ? 15 : 13,
                              ),
                            ),
                            if (ad.subtitle.isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Text(
                                ad.subtitle,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.82),
                                  fontWeight: FontWeight.w400,
                                  fontSize: widget.isDesktop ? 13 : 11,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      _buildDots(safeIndex, total),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── YouTube ad ────────────────────────────────────────────────────────────
  Widget _buildYoutubeContent(
      AdModel ad, int safeIndex, int total, bool isDark, Color textPrimary, Color textMuted) {
    final p = widget.isDesktop ? 22.0 : 18.0;

    final closeButton = GestureDetector(
      onTap: _dismissYoutubeAd,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.65),
          shape: BoxShape.circle,
        ),
        padding: const EdgeInsets.all(6),
        child: const Icon(Icons.close, color: Colors.white, size: 18),
      ),
    );

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(16)),
            child: _YoutubeAdWidget(
              youtubeId: ad.youtubeId!,
              onVideoEnded: _advanceToNext,
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
                horizontal: p, vertical: widget.isDesktop ? 14 : 10),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF111111), Color(0xFF1A1A1A)],
              ),
              borderRadius:
                  BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ad.title,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: widget.isDesktop ? 14 : 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (ad.subtitle.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          ad.subtitle,
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: widget.isDesktop ? 12 : 10,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _buildDots(safeIndex, total),
                const SizedBox(width: 8),
                closeButton,
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ads = widget.ads;
    if (ads.isEmpty) return const SizedBox.shrink();

    final safeIndex = _index % ads.length;
    final ad = ads[safeIndex];

    // Resolve theme colors from context
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final textPrimary = isDark ? const Color(0xFFF0F6FF) : const Color(0xFF0D1B2E);
    final textMuted = isDark ? const Color(0xFF7A94B0) : const Color(0xFF5A7090);

    final carousel = AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: child,
      ),
      child: KeyedSubtree(
        key: ValueKey(safeIndex),
        child: switch (ad.adType) {
          AdModel.typeImage when (ad.imageUrl ?? '').isNotEmpty =>
            _buildImageContent(ad, safeIndex, ads.length),
          AdModel.typeYoutube when (ad.youtubeId ?? '').isNotEmpty =>
            _youtubeDismissed
                ? _buildTextContent(ad, safeIndex, ads.length, isDark, textPrimary, textMuted)
                : _buildYoutubeContent(ad, safeIndex, ads.length, isDark, textPrimary, textMuted),
          _ => _buildTextContent(ad, safeIndex, ads.length, isDark, textPrimary, textMuted),
        },
      ),
    );

    if (ads.length <= 1) return carousel;

    return Stack(
      children: [
        carousel,
        Positioned(
          left: 4,
          top: 0,
          bottom: 0,
          child: Center(
            child: GestureDetector(
              onTap: _prevSlide,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.all(6),
                child: const Icon(Icons.chevron_left,
                    color: Colors.white, size: 22),
              ),
            ),
          ),
        ),
        Positioned(
          right: 4,
          top: 0,
          bottom: 0,
          child: Center(
            child: GestureDetector(
              onTap: _advanceToNext,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.all(6),
                child: const Icon(Icons.chevron_right,
                    color: Colors.white, size: 22),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── YouTube inline player widget ──────────────────────────────────────────────

class _YoutubeAdWidget extends StatefulWidget {
  final String youtubeId;
  final VoidCallback onVideoEnded;
  const _YoutubeAdWidget({required this.youtubeId, required this.onVideoEnded});

  @override
  State<_YoutubeAdWidget> createState() => _YoutubeAdWidgetState();
}

class _YoutubeAdWidgetState extends State<_YoutubeAdWidget> {
  late YoutubePlayerController _controller;
  StreamSubscription<YoutubePlayerValue>? _sub;
  bool _playInitiated = false;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController.fromVideoId(
      videoId: widget.youtubeId,
      autoPlay: true,
      params: const YoutubePlayerParams(
        mute: true,
        showControls: true,
        showFullscreenButton: false,
        loop: false,
        origin: 'https://www.youtube.com',
      ),
    );
    _sub = _controller.stream.listen((value) {
      if (value.playerState == PlayerState.ended) {
        _playInitiated = false;
        widget.onVideoEnded();
      } else if (!_playInitiated &&
          (value.playerState == PlayerState.unStarted ||
              value.playerState == PlayerState.cued)) {
        _playInitiated = true;
        _controller.playVideo();
      }
    });
  }

  @override
  void didUpdateWidget(_YoutubeAdWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.youtubeId != widget.youtubeId) {
      _playInitiated = false;
      _controller.loadVideoById(videoId: widget.youtubeId);
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return YoutubePlayer(
      controller: _controller,
      aspectRatio: 16 / 9,
    );
  }
}
