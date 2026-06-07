import 'package:flutter/material.dart';
import '../../../data/models/qobuz_models.dart';

class TrackListTile extends StatelessWidget {
  final QobuzTrack track;
  final VoidCallback onDownload;

  const TrackListTile({
    super.key,
    required this.track,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Text(track.trackNumber?.toString() ?? '-'),
      title: Text(track.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        "${track.performer?.name ?? 'Unknown'} • ${_formatDuration(track.duration ?? 0)}",
      ),
      trailing: IconButton(
        icon: const Icon(Icons.download),
        onPressed: onDownload,
      ),
    );
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return "$m:${s.toString().padLeft(2, '0')}";
  }
}
