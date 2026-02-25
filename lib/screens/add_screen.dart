import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:hive/hive.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../services/chat_service.dart';
import 'chat_screen.dart';
import 'group_screen.dart';

class AddScreen extends StatefulWidget {
  const AddScreen({super.key});

  @override
  State<AddScreen> createState() => _AddScreenState();
}

class _AddScreenState extends State<AddScreen> {
  List<Map<String, dynamic>> _onechatContacts = [];
  List<Contact> _allContacts = [];
  bool _isLoading = false;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts({bool forceRefresh = false}) async {
    setState(() => _isLoading = true);
    final box = Hive.box('contacts_cache');
    final cached = box.get('onechat_contacts');
    
    if (cached != null && !forceRefresh) {
      _onechatContacts = List<Map<String, dynamic>>.from(jsonDecode(cached));
      setState(() => _isLoading = false);
      return;
    }

    // Request contacts permission
    final status = await Permission.contacts.request();
    if (!status.isGranted) {
      setState(() => _isLoading = false);
      return;
    }

    _allContacts = await FlutterContacts.getContacts(withProperties: true);
    final phones = _allContacts
        .expand((c) => c.phones.map((p) => p.number.replaceAll(RegExp(r'[^0-9+]'), '')))
        .where((p) => p.isNotEmpty)
        .toList();

    if (phones.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    final chatService = Provider.of<ChatService>(context, listen: false);
    final results = await chatService.checkContacts(phones);

    // Map results back to contact names
    final phoneToName = <String, String>{};
    for (final contact in _allContacts) {
      for (final phone in contact.phones) {
        final clean = phone.number.replaceAll(RegExp(r'[^0-9+]'), '');
        phoneToName[clean] = contact.displayName;
      }
    }

    _onechatContacts = results.map((r) {
      final phone = r['phone'] as String;
      return {
        ...r,
        'display_name': phoneToName[phone] ?? r['name'] ?? phone,
      };
    }).toList();

    await box.put('onechat_contacts', jsonEncode(_onechatContacts));
    if (mounted) setState(() => _isLoading = false);
  }

  List<Map<String, dynamic>> get _filtered {
    if (_search.isEmpty) return _onechatContacts;
    return _onechatContacts
        .where((c) =>
            (c['display_name'] as String).toLowerCase().contains(_search.toLowerCase()) ||
            (c['phone'] as String).contains(_search))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Chat'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadContacts(forceRefresh: true),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: 'Search contacts...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          
          // Create Group option
          ListTile(
            leading: CircleAvatar(
              backgroundColor: theme.colorScheme.secondaryContainer,
              child: Icon(Icons.group, color: theme.colorScheme.onSecondaryContainer),
            ),
            title: const Text('Create Group', style: TextStyle(fontWeight: FontWeight.w600)),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => GroupScreen(contacts: _onechatContacts)),
            ),
          ),
          const Divider(indent: 16, endIndent: 16),
          
          _isLoading
              ? const Expanded(child: Center(child: CircularProgressIndicator()))
              : _filtered.isEmpty
                  ? Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.contacts, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              _onechatContacts.isEmpty
                                  ? 'No OneChat contacts found'
                                  : 'No results',
                              style: TextStyle(color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Expanded(
                      child: ListView.builder(
                        itemCount: _filtered.length,
                        itemBuilder: (ctx, i) {
                          final contact = _filtered[i];
                          final name = contact['display_name'] as String;
                          final phone = contact['phone'] as String;
                          final userId = contact['user_id'].toString();
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: theme.colorScheme.primaryContainer,
                              child: Text(
                                name.isNotEmpty ? name[0].toUpperCase() : '?',
                                style: TextStyle(color: theme.colorScheme.onPrimaryContainer),
                              ),
                            ),
                            title: Text(name),
                            subtitle: Text(phone),
                            trailing: const Icon(Icons.chat_bubble_outline, size: 18),
                            onTap: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChatScreen(
                                    userId: userId,
                                    userName: name,
                                    userPhone: phone,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
        ],
      ),
    );
  }
}
