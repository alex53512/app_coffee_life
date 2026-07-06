import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../services/offline_queue_service.dart';
import '../services/sync_service.dart';

class OfflineBanner extends StatelessWidget {
  final Widget child;

  const OfflineBanner({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ValueListenableBuilder<bool>(
          valueListenable: ApiService.isOffline,
          builder: (ctx, offline, _) {
            if (!offline) return const SizedBox.shrink();
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
              color: Colors.orange.shade700,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_off_rounded, size: 16, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Sin conexión — mostrando datos guardados',
                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            );
          },
        ),
        ValueListenableBuilder<int>(
          valueListenable: OfflineQueueService.pendingCount,
          builder: (ctx, count, _) {
            if (count == 0) return const SizedBox.shrink();
            return GestureDetector(
              onTap: () => SyncService.syncAll(),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                color: Colors.blue.shade600,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.sync_rounded, size: 16, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      '$count diagnóstico${count == 1 ? '' : 's'} pendiente${count == 1 ? '' : 's'} de envío — toca para sincronizar',
                      style: GoogleFonts.nunito(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        Expanded(child: child),
      ],
    );
  }
}
