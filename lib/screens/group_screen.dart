import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/chat_service.dart';

class GroupScreen extends StatefulWidget {
  final List<Map<String, dynamic>> contacts;
  const GroupScreen({super.key, required this.contacts});

  @override
  State<GroupScreen> createState() => _GroupScreenState();
}

class _GroupScreenState extends State<GroupScreen> {
  final _nameCtrl = TextEditingController();
  final Set<String> _selected = {};
  bool _isCreating = false;

  void _create() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter group name')));
      return;
    }
    if (_selected.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select at least 2 members')));
      return;
    }
    setState(() => _isCreating = true);
    final chatService = Provider.of<ChatService>(context, listen: false);
    final result = await chatService.createGroup(_nameCtrl.text.trim(), _selected.toList());
    if (!mounted) return;
    setState(() => _isCreating = false);
    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Group created!')));
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Failed to create group')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Group'),
        actions: [
          TextButton(
            onPressed: _isCreating ? null : _create,
            child: _isCreating
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Create'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Group Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.group),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Select members (${_selected.length} selected)',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: widget.contacts.length,
              itemBuilder: (ctx, i) {
                final c = widget.contacts[i];
                final userId = c['user_id'].toString();
                final name = c['display_name'] as String;
                final phone = c['phone'] as String;
                final isSelected = _selected.contains(userId);
                return CheckboxListTile(
                  value: isSelected,
                  onChanged: (v) => setState(() {
                    if (v == true) _selected.add(userId);
                    else _selected.remove(userId);
                  }),
                  secondary: CircleAvatar(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Text(name[0].toUpperCase(),
                        style: TextStyle(color: theme.colorScheme.onPrimaryContainer)),
                  ),
                  title: Text(name),
                  subtitle: Text(phone),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
