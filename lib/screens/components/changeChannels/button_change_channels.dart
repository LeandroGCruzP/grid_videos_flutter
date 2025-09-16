import 'package:flutter/material.dart';
import 'package:multi_video/screens/components/changeChannels/channel_option.dart';
import 'package:multi_video/screens/const/sync_const.dart';
import 'package:multi_video/screens/controllers/sync_video_controller.dart';

class ButtonChangeChannels extends StatelessWidget {
  final SyncVideoController syncController;

  const ButtonChangeChannels({
    super.key,
    required this.syncController,
  });

  void _showChannelsTooltip(BuildContext context) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;

    final buttonPosition = button.localToGlobal(Offset.zero, ancestor: overlay);

    showGeneralDialog<String>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Stack(
          children: [
            Positioned(
              right: 10,
              bottom: overlay.size.height - buttonPosition.dy,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF5D5D5D).withOpacity(0.7),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Canais',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '${syncController.selectedChannels.length}/$maxChannelsToShow',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                              fontSize: 8,
                            ),
                          ),
                        ],
                      ),
                      ...syncController.allChannelsKeys.map(
                        (channel) => GestureDetector(
                          onTap: () {
                            syncController.toggleChannel(channel);
                          },
                          child: ChannelOption(
                            channel: channel,
                            isSelected: syncController.isChannelSelected(channel),
                            onTap: () => syncController.toggleChannel(channel),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved =
            CurvedAnimation(parent: animation, curve: Curves.easeOut);
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.2), // Appears coming from below
            end: Offset.zero,
          ).animate(curved),
          child: FadeTransition(
            opacity: curved,
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => _showChannelsTooltip(context),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF5D5D5D),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        minimumSize: const Size(0, 30),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.swap_horiz, size: 16, color: Colors.white),
          SizedBox(width: 5),
          Text(
            'Trocar canais',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFFFFC501),
            ),
          ),
        ],
      ),
    );
  }
}
