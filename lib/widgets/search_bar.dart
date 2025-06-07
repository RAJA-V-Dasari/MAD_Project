import 'package:flutter/material.dart';

class SearchBarWidget extends StatelessWidget {
  final String hintText;
  final TextEditingController? controller;
  final VoidCallback? onSearch;
  final VoidCallback? onClear;

  const SearchBarWidget({
    super.key,
    this.hintText = "Search...",
    this.controller,
    this.onSearch,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.purple[50],
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: hintText,
                border: InputBorder.none,
              ),
              // No onChanged here for filtering on typing
              // User will type freely
              onSubmitted:
                  (_) => onSearch?.call(), // Optional: search on Enter key
            ),
          ),
          if (controller != null && controller!.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                controller!.clear();
                if (onClear != null)
                  onClear!(); // Notify parent to clear search/filter
              },
              child: const Icon(Icons.clear),
            )
          else
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: onSearch, // User taps to trigger search
            ),
        ],
      ),
    );
  }
}
