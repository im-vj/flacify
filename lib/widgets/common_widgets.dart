import 'package:flutter/material.dart';

class SectionTitle extends StatelessWidget {
  final String title;
  final EdgeInsets padding;

  const SectionTitle(this.title, {super.key, this.padding = const EdgeInsets.fromLTRB(16, 24, 16, 8)});

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: padding,
      sliver: SliverToBoxAdapter(
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: -0.3,
          ),
        ),
      ),
    );
  }
}

class LoadingIndicator extends StatelessWidget {
  final Color? color;
  final double size;

  const LoadingIndicator({super.key, this.color, this.size = 24});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
          color: color ?? Colors.white38,
          strokeWidth: 2,
        ),
      ),
    );
  }
}

class ErrorDisplay extends StatelessWidget {
  final Object error;
  final VoidCallback? onRetry;

  const ErrorDisplay(this.error, {super.key, this.onRetry});

  String get _friendlyMessage {
    final msg = error.toString();
    if (msg.contains('SocketException') || msg.contains('Failed host lookup') || msg.contains('connection errored')) {
      return 'You appear to be offline or the server is unreachable.';
    }
    if (msg.contains('Connection timeout') || msg.contains('receive timeout')) {
      return 'Connection timed out. Please try again.';
    }
    return msg;
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white38, size: 36),
            const SizedBox(height: 12),
            Text(
              _friendlyMessage,
              style: const TextStyle(color: Colors.white54, fontSize: 13),
              textAlign: TextAlign.center,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 16, color: Colors.white70),
                label: const Text('Retry', style: TextStyle(color: Colors.white70)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white24),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final String message;
  final IconData icon;

  const EmptyState({super.key, this.message = 'Nothing here', this.icon = Icons.music_note_rounded});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: Colors.white24),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(color: Colors.white38)),
        ],
      ),
    );
  }
}

class AlbumArtPlaceholder extends StatelessWidget {
  final double size;
  final double borderRadius;

  const AlbumArtPlaceholder({
    super.key,
    this.size = 40,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: const Icon(Icons.album_rounded, color: Colors.white24, size: 24),
    );
  }
}
