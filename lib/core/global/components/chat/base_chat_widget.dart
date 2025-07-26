import 'package:flutter/material.dart';
import 'package:freeaihub/core/models/chat/message.dart';
import 'package:sizer/sizer.dart';

class BaseChatWidget extends StatefulWidget {
  final List<Message> messages;
  final void Function(String) onSendPressed;
  final MessageAuthor user;
  final Widget Function(Message) messageBuilder;
  final Widget Function(dynamic)? thinkBlockBuilder; // For things like ThinkBlock
  final Widget? bottomWidget; // For the input area and other tools
  final Widget? emptyState;
  final Widget? listBottomWidget;
  final Widget? typingIndicator; // Separate typing indicator widget
  final double? imageMaxHeight; // Max height for image messages in dp

  /// Optional external [ScrollController]. If not provided, the widget will
  /// create its own controller internally. Supplying one allows the parent
  /// to listen to scroll events as needed.
  final ScrollController? scrollController;

  const BaseChatWidget({
    super.key,
    required this.messages,
    required this.onSendPressed,
    required this.user,
    required this.messageBuilder,
    this.thinkBlockBuilder,
    this.bottomWidget,
    this.emptyState,
    this.listBottomWidget,
    this.typingIndicator, // Separate typing indicator widget
    this.imageMaxHeight,
    this.scrollController,
  });

  @override
  State<BaseChatWidget> createState() => _BaseChatWidgetState();
}

class _BaseChatWidgetState extends State<BaseChatWidget> {
  final TextEditingController _textController = TextEditingController();

  // Scroll controller will be either the externally supplied controller or a
  // lazily-created internal one.
  late final ScrollController _scrollController;

  // Track whether the view is currently scrolled to the bottom. This is used
  // to decide whether to show the input area or the jump-to-bottom button.
  bool _isAtBottom = true;

  @override
  void initState() {
    super.initState();

    _scrollController = widget.scrollController ?? ScrollController();

    // Listen to scroll events to determine if we are at the bottom.
    _scrollController.addListener(_onScroll);
  }

  /// Listener that updates [_isAtBottom] depending on the current scroll
  /// offset. Because the list is built with `reverse: true`, an offset close
  /// to zero actually means we are at the bottom (latest message).
  void _onScroll() {
    double threshold = 50.h; // px – tweak as necessary
    final bool atBottom = !_scrollController.hasClients
        ? true
        : _scrollController.position.pixels <= threshold;

    if (atBottom != _isAtBottom) {
      setState(() {
        _isAtBottom = atBottom;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget chatColumn = Column(
      children: [
        Expanded(
          child: widget.messages.isEmpty && widget.emptyState != null
              ? widget.emptyState!
              : CustomScrollView(
                  controller: _scrollController,
                  reverse: true,
                  physics: const ClampingScrollPhysics(),
                  cacheExtent: 500.0,
                  slivers: [
                    SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final message = widget.messages[index];

                        Widget messageContent;

                        if (widget.thinkBlockBuilder != null &&
                            message.type == MessageType.thinkBlock &&
                            message.text.isNotEmpty) {
                          messageContent = widget.thinkBlockBuilder!(message);
                        } else if (message.type == MessageType.text ||
                            message.type == MessageType.image ||
                            message.type == MessageType.document) {
                          // Render text, image, and document messages
                          // For image and document messages, we don't require text to be non-empty
                          if (message.type == MessageType.text && message.text.isEmpty) {
                            messageContent = SizedBox.shrink();
                          } else {
                            messageContent = widget.messageBuilder(message);
                          }
                        } else {
                          messageContent = SizedBox.shrink();
                        }

                        bool isCurrentUser = message.author.type == widget.user.type;

                        return Align(
                          alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                            child: messageContent,
                          ),
                        );
                      }, childCount: widget.messages.length),
                    ),
                    // Add "Start of conversation" label at the beginning if there are messages
                    if (widget.messages.isNotEmpty)
                      SliverToBoxAdapter(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: Center(
                            child: Text(
                              'Start of conversation',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(
                                  context,
                                ).textTheme.bodySmall?.color?.withOpacity(0.5),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
        ),
        // Add typing indicator between messages and bottom widgets
        if (widget.typingIndicator != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Align(alignment: Alignment.centerLeft, child: widget.typingIndicator!),
          ),
        if (widget.listBottomWidget != null) widget.listBottomWidget!,

        // Show the input area only when the user is at the bottom of the list
        if (_isAtBottom && widget.bottomWidget != null) widget.bottomWidget!,
      ],
    );

    return Stack(
      children: [
        chatColumn,

        // Floating jump-to-bottom button
        if (!_isAtBottom)
          Positioned(
            right: 16,
            bottom: 16,
            child: Material(
              color: Theme.of(context).colorScheme.primary,
              shape: const CircleBorder(),
              elevation: 4,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () {
                  _scrollController.animateTo(
                    0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Icon(Icons.arrow_downward, color: Theme.of(context).colorScheme.onPrimary),
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    // Dispose only if we created the controller internally.
    if (widget.scrollController == null) {
      _scrollController.dispose();
    } else {
      _scrollController.removeListener(_onScroll);
    }
    super.dispose();
  }
}
