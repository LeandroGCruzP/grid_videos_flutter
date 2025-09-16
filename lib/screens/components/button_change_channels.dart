import 'package:flutter/material.dart';
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
                            '${syncController.selectedChannelsCount}/$maxChannelsToShow',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                              fontSize: 8,
                            ),
                          ),
                        ],
                      ),
                      ...syncController.controllers.keys.map((channelId) => 'Canal $channelId').map(
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

/// Custom Menu Item that makes only its child clickable
class CustomMenuItem extends PopupMenuEntry<String> {
  final String value;
  final Widget child;

  const CustomMenuItem({super.key, required this.value, required this.child});

  @override
  double get height => kMinInteractiveDimension;

  @override
  bool represents(String? value) => value == this.value;

  @override
  State createState() => _CustomMenuItemState();
}

class _CustomMenuItemState extends State<CustomMenuItem> {
  void onPressed() {
    // Add functionality here
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      // Centraliza se o menu for mais largo
      child: InkWell(
        borderRadius: BorderRadius.circular(35),
        onTap: onPressed,
        child: widget.child,
      ),
    );
  }
}

class ChannelOption extends StatelessWidget {
  final String channel;
  final VoidCallback onTap;
  final bool isSelected;

  const ChannelOption({
    super.key,
    required this.channel,
    required this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 5),
      padding: const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF3D3D3C),
        borderRadius: BorderRadius.circular(35),
        border: Border.all(
          color: isSelected ? const Color(0xFFFFC501) : Colors.transparent, 
          width: 1
        ),
      ),
      child: Text(
        channel,
        style: const TextStyle(
          color: Color(0xFFFFC501),
          fontWeight: FontWeight.w500,
          fontSize: 10,
        ),
      ),
    );
  }
}
