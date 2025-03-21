import 'package:flutter/material.dart';
import 'dart:async';

class AdvancedSearchBar extends StatefulWidget {
  final Function(String) onSearch;
  final Function() onClear;
  final Function() onFilterTap;
  final String filterText;
  final String hintText;
  final bool isSearching;
  
  const AdvancedSearchBar({
    Key? key,
    required this.onSearch,
    required this.onClear,
    required this.onFilterTap,
    required this.filterText,
    this.hintText = 'Search for products...',
    this.isSearching = false,
  }) : super(key: key);

  @override
  _AdvancedSearchBarState createState() => _AdvancedSearchBarState();
}

class _AdvancedSearchBarState extends State<AdvancedSearchBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;
  bool _showClear = false;
  Timer? _debounce;
  
  @override
  void initState() {
    super.initState();
    _controller.addListener(_onInputChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.removeListener(_onInputChanged);
    _controller.dispose();
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _onInputChanged() {
    setState(() {
      _showClear = _controller.text.isNotEmpty;
    });
    
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      widget.onSearch(_controller.text);
    });
  }

  void _onFocusChanged() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  void _clearSearch() {
    _controller.clear();
    widget.onClear();
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30.0),
        border: Border.all(
          color: _isFocused ? Theme.of(context).primaryColor : Colors.grey.shade300,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          // Search Icon
          Container(
            width: 50,
            child: Icon(
              Icons.search,
              color: _isFocused 
                  ? Theme.of(context).primaryColor
                  : Colors.grey.shade500,
              size: _isFocused ? 24 : 22,
            ),
          ),
          
          // Text Input Field
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: TextStyle(
                  fontSize: 15, 
                  color: Colors.grey.shade400,
                  fontWeight: FontWeight.w400,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 14.0),
              ),
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: widget.onSearch,
            ),
          ),
          
          // Show spinner when searching or clear button
          if (widget.isSearching)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: SizedBox(
                height: 16, 
                width: 16, 
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            )
          else if (_showClear)
            IconButton(
              icon: Icon(Icons.clear, color: Colors.grey.shade500, size: 20),
              onPressed: _clearSearch,
              splashRadius: 20,
            ),
          
          // Filter Chip
          GestureDetector(
            onTap: widget.onFilterTap,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
              margin: EdgeInsets.only(right: 8.0),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16.0),
                border: Border.all(color: Colors.grey.shade300, width: 0.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.filter_list,
                    size: 14,
                    color: Colors.grey.shade700,
                  ),
                  SizedBox(width: 4),
                  Text(
                    widget.filterText,
                    style: TextStyle(
                      fontSize: 12.0, 
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}