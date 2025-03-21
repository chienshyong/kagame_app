import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';
import '../shop/product_detail_page.dart';

class StyleMeTab extends StatefulWidget {
  final AuthService authService;
  
  const StyleMeTab({Key? key, required this.authService}) : super(key: key);

  @override
  _StyleMeTabState createState() => _StyleMeTabState();
}

class _StyleMeTabState extends State<StyleMeTab> {
  final TextEditingController _promptController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  
  bool _isLoading = false;
  String _loadingMessage = "Processing...";
  List<Map<String, dynamic>> _outfitItems = [];
  Map<String, List<Map<String, dynamic>>> _categorizedItems = {};
  List<Map<String, dynamic>> _outfits = [];
  String? _errorMessage;
  
  @override
  void dispose() {
    _promptController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleStyleMeSubmit() async {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty || _isLoading) return;
    
    // Add user message to chat
    setState(() {
      _messages.add(ChatMessage(
        role: 'user',
        content: prompt,
      ));
      _isLoading = true;
      _loadingMessage = "Analyzing your style request...";
      _outfitItems = [];
      _categorizedItems = {};
      _outfits = [];
      _errorMessage = null;
    });
    
    // Clear input field
    _promptController.clear();
    
    // Scroll to bottom
    _scrollToBottom();
    
    try {
      // Get token
      final String baseUrl = widget.authService.baseUrl;
      final token = await widget.authService.getToken();
      
      // Create a conversation history from existing messages
      final conversationHistory = _messages.map((msg) => {
        'role': msg.role,
        'content': msg.content,
      }).toList();
      
      // Start streaming response
      await _streamStyleResponse(baseUrl, token, prompt, conversationHistory);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = "An error occurred: $e";
        _messages.add(ChatMessage(
          role: 'assistant',
          content: "Sorry, I encountered a problem. Please try again.",
        ));
      });
      _scrollToBottom();
    }
  }
  
  Future<void> _streamStyleResponse(String baseUrl, String? token, String prompt, List<Map<String, dynamic>> conversationHistory) async {
    // Encode the conversation history to send as a query parameter
    final jsonHistory = json.encode(conversationHistory);
    final encodedHistory = Uri.encodeComponent(jsonHistory);
        
    final url = Uri.parse('$baseUrl/chat-outfit-search-stream');
    final request = http.Request('POST', url);

    // We need to send JSON in the body, for example:
    request.headers['Content-Type'] = 'application/json';
      request.headers['Authorization'] = 'Bearer $token';
    request.body = json.encode({
      "prompt": prompt,
      "conversation_history": conversationHistory,
    });

    // Then send the request
    final response = await request.send();
    
    if (response.statusCode != 200) {
      throw Exception('Failed to get style recommendations: ${response.statusCode}');
    }
    
    // Listen to the stream
    response.stream.transform(utf8.decoder).transform(const LineSplitter()).listen(
      (String line) {
        // Skip empty lines
        if (line.isEmpty) return;
        
        // Check if line starts with "data: "
        if (line.startsWith('data: ')) {
          // Extract the JSON data
          final jsonData = line.substring(6);
          try {
            final data = json.decode(jsonData);
            
            // Handle different status messages
            if (data['status'] == 'processing') {
              setState(() {
                _loadingMessage = data['message'] ?? "Processing...";
              });
            } else if (data['status'] == 'tag_generated') {
              setState(() {
                _loadingMessage = "Finding the perfect items for you...";
              });
            } else if (data['status'] == 'searching') {
              setState(() {
                _loadingMessage = data['message'] ?? "Searching...";
              });
            } else if (data['status'] == 'complete') {
              // Update state with results
              setState(() {
                _isLoading = false;
                
                // Add assistant message
                if (data['chat_message'] != null) {
                  _messages.add(ChatMessage(
                    role: 'assistant',
                    content: data['chat_message'],
                  ));
                }
                
                // Store results
                if (data['outfit_items'] != null) {
                  _outfitItems = List<Map<String, dynamic>>.from(data['outfit_items']);
                }
                
                if (data['categorized_items'] != null) {
                  final categorized = data['categorized_items'] as Map<String, dynamic>;
                  _categorizedItems = {};
                  
                  categorized.forEach((key, value) {
                    if (value is List) {
                      _categorizedItems[key] = List<Map<String, dynamic>>.from(value);
                    }
                  });
                }
                
                if (data['outfits'] != null) {
                  _outfits = List<Map<String, dynamic>>.from(data['outfits']);
                }
              });
              
              _scrollToBottom();
            } else if (data['status'] == 'error') {
              setState(() {
                _isLoading = false;
                _errorMessage = data['message'];
                _messages.add(ChatMessage(
                  role: 'assistant',
                  content: "Sorry, I encountered an error: ${data['message']}",
                ));
              });
              
              _scrollToBottom();
            }
          } catch (e) {
            print('Error parsing SSE data: $e');
          }
        }
      },
      onError: (e) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
          _messages.add(ChatMessage(
            role: 'assistant',
            content: "Sorry, I encountered an error while communicating with the style service.",
          ));
        });
        
        _scrollToBottom();
      },
      onDone: () {
        // If we're still loading when the stream completes, something went wrong
        if (_isLoading) {
          setState(() {
            _isLoading = false;
            _messages.add(ChatMessage(
              role: 'assistant',
              content: "Sorry, the style service disconnected unexpectedly.",
            ));
          });
          
          _scrollToBottom();
        }
      },
    );
  }
  
  void _scrollToBottom() {
    // Use a short delay to ensure the list has been updated
    Future.delayed(Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget _buildStyleMeInput() {
    return Container(
      padding: EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            offset: Offset(0, -2),
            blurRadius: 4.0,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _promptController,
              decoration: InputDecoration(
                hintText: "Describe what you're looking for...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
                contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              ),
              onSubmitted: (_) => _handleStyleMeSubmit(),
            ),
          ),
          SizedBox(width: 8.0),
          ElevatedButton(
            onPressed: _isLoading ? null : _handleStyleMeSubmit,
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24.0),
              ),
              padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
              backgroundColor: Theme.of(context).primaryColor,
            ),
            child: _isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.0,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    'Style Me',
                    style: TextStyle(color: Colors.white),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatMessage(ChatMessage message) {
    final isUser = message.role == 'user';
    
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
        decoration: BoxDecoration(
          color: isUser ? Theme.of(context).primaryColor : Colors.grey[200],
          borderRadius: BorderRadius.circular(16.0),
        ),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        child: Text(
          message.content,
          style: TextStyle(
            color: isUser ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _buildOutfitDisplay(Map<String, dynamic> outfit, int index) {
    final items = outfit['items'] as Map<String, dynamic>;
    
    return Card(
      margin: EdgeInsets.only(bottom: 16.0),
      elevation: 2.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Outfit ${index + 1}',
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (outfit['description'] != null)
                  Padding(
                    padding: EdgeInsets.only(top: 4.0),
                    child: Text(
                      outfit['description'],
                      style: TextStyle(
                        fontSize: 14.0,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.0),
            child: Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: items.entries.map<Widget>((entry) {
                final item = entry.value;
                if (item == null) return SizedBox.shrink();
                
                return _buildItemCard(item, entry.key);
              }).toList(),
            ),
          ),
          SizedBox(height: 12.0),
        ],
      ),
    );
  }

  Widget _buildItemCard(Map<String, dynamic> item, String itemType) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailPage(productId: item['id']),
          ),
        );
      },
      child: Container(
        width: MediaQuery.of(context).size.width * 0.4,
        child: Card(
          elevation: 1.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 140,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(8.0)),
                  image: DecorationImage(
                    image: NetworkImage(item['image_url'] ?? ''),
                    fit: BoxFit.cover,
                    onError: (_, __) {
                      // Handle image loading errors
                    },
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      itemType.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 4.0),
                    Text(
                      item['name'] ?? '',
                      style: TextStyle(
                        fontSize: 14.0,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.0),
                    Text(
                      '\$${item['price']}',
                      style: TextStyle(
                        fontSize: 14.0,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryItems(String category, List<Map<String, dynamic>> items) {
    if (items.isEmpty) return SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            category,
            style: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(
          height: 250.0,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 12.0),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Container(
                width: 160.0,
                margin: EdgeInsets.only(right: 12.0),
                child: _buildItemCard(item, category),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              // Chat messages and results
              ListView(
                controller: _scrollController,
                padding: EdgeInsets.only(bottom: 16.0),
                children: [
                  // Welcome message if no messages yet
                  if (_messages.isEmpty)
                    Container(
                      margin: EdgeInsets.all(20.0),
                      padding: EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12.0),
                        border: Border.all(color: Colors.blue[100]!),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.chat,
                            size: 48.0,
                            color: Theme.of(context).primaryColor,
                          ),
                          SizedBox(height: 12.0),
                          Text(
                            'Style Assistant',
                            style: TextStyle(
                              fontSize: 20.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8.0),
                          Text(
                            'I can help you find the perfect outfit! Describe what you\'re looking for or a specific occasion.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16.0,
                            ),
                          ),
                          SizedBox(height: 16.0),
                          Text(
                            'Examples: "Business casual for summer", "Date night outfit", "Casual beach wedding"',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14.0,
                              fontStyle: FontStyle.italic,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  // Chat messages
                  ...(_messages.map(_buildChatMessage).toList()),
                  
                  // Loading indicator
                  if (_isLoading)
                    Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 20.0,
                            height: 20.0,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.0,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Theme.of(context).primaryColor,
                              ),
                            ),
                          ),
                          SizedBox(width: 12.0),
                          Text(_loadingMessage),
                        ],
                      ),
                    ),
                  
                  // Results section
                  if (_outfits.isNotEmpty || _categorizedItems.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_outfits.isNotEmpty) ...[
                            Text(
                              'Outfit Suggestions',
                              style: TextStyle(
                                fontSize: 20.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 12.0),
                            ..._outfits.asMap().entries.map(
                              (entry) => _buildOutfitDisplay(entry.value, entry.key),
                            ),
                          ],
                          
                          if (_categorizedItems.isNotEmpty) ...[
                            SizedBox(height: 16.0),
                            Text(
                              'Individual Items',
                              style: TextStyle(
                                fontSize: 20.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 12.0),
                            ..._categorizedItems.entries.where((e) => e.value.isNotEmpty).map(
                              (entry) => _buildCategoryItems(entry.key, entry.value),
                            ),
                          ],
                        ],
                      ),
                    ),
                ],
              ),
              
              // Error message snackbar-style display
              if (_errorMessage != null)
                Positioned(
                  top: 16.0,
                  left: 16.0,
                  right: 16.0,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    decoration: BoxDecoration(
                      color: Colors.red[400],
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error, color: Colors.white),
                        SizedBox(width: 12.0),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: Colors.white),
                          onPressed: () {
                            setState(() {
                              _errorMessage = null;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        
        // Input field and button
        _buildStyleMeInput(),
      ],
    );
  }
}

// Simple chat message model
class ChatMessage {
  final String role; // 'user' or 'assistant'
  final String content;
  
  ChatMessage({
    required this.role,
    required this.content,
  });
}