import 'package:flutter/material.dart';
import 'package:homeease/presentation/location_picker/models/location_picker_result.dart';

class LocationSearchField extends StatelessWidget {
  final TextEditingController controller;
  final List<PlaceSuggestion> suggestions;
  final bool isSearching;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<PlaceSuggestion> onSuggestionSelected;
  final VoidCallback? onClear;

  const LocationSearchField({
    super.key,
    required this.controller,
    required this.suggestions,
    required this.isSearching,
    required this.onQueryChanged,
    required this.onSuggestionSelected,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(16),
      color: theme.cardColor,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: 'Search address or place',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isSearching)
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  else if (controller.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: onClear,
                    ),
                ],
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: theme.cardColor,
            ),
            onChanged: onQueryChanged,
          ),
          if (suggestions.isNotEmpty)
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220),
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: suggestions.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = suggestions[index];
                  return ListTile(
                    dense: true,
                    leading: Icon(
                      Icons.place_outlined,
                      color: theme.colorScheme.primary,
                    ),
                    title: Text(
                      item.mainText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: item.secondaryText != null
                        ? Text(
                            item.secondaryText!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          )
                        : null,
                    onTap: () => onSuggestionSelected(item),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
