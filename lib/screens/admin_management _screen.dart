import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Admin directory and moderation tools for users, experts and resources.
/// This screen expects to be opened from the existing Admin Dashboard.
class AdminManagementScreen extends StatefulWidget {
  const AdminManagementScreen({super.key});

  @override
  State<AdminManagementScreen> createState() => _AdminManagementScreenState();
}

class _AdminManagementScreenState extends State<AdminManagementScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  late final TabController _tabController;
  String _statusFilter = 'All';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() => _statusFilter = 'All');
        _searchController.clear();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _message(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  String _text(dynamic value, [String fallback = 'Not provided']) {
    if (value == null || value.toString().trim().isEmpty) return fallback;
    return value.toString().trim();
  }

  bool _matches(Map<String, dynamic> data, String query) {
    if (query.isEmpty) return true;
    final haystack = data.entries
        .map((entry) => '${entry.key} ${entry.value}')
        .join(' ')
        .toLowerCase();
    return haystack.contains(query.toLowerCase());
  }

  Future<String?> _askReason(String itemType, String itemName) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Reject $itemType'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Reason for rejecting "$itemName":'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Reason',
                hintText: 'Enter a reason (optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  Future<void> _setExpertStatus({
    required String id,
    required String name,
    required bool approve,
  }) async {
    String? reason;
    if (!approve) {
      reason = await _askReason('expert application', name);
      if (reason == null) return;
    }
    try {
      final adminId = FirebaseAuth.instance.currentUser?.uid;
      final changes = <String, dynamic>{
        'status': approve ? 'approved' : 'rejected',
        'updatedAt': FieldValue.serverTimestamp(),
        if (approve) ...{
          'verifiedAt': FieldValue.serverTimestamp(),
          'verifiedBy': adminId,
          'rejectionReason': FieldValue.delete(),
        } else ...{
          'rejectedAt': FieldValue.serverTimestamp(),
          'rejectedBy': adminId,
          'rejectionReason': reason,
        },
      };
      await _firestore.collection('experts').doc(id).update(changes);
      _message(approve ? 'Expert approved.' : 'Expert application rejected.');
    } catch (e) {
      _message('Could not update expert: $e');
    }
  }

  Future<void> _setResourceStatus({
    required String id,
    required String title,
    required bool approve,
  }) async {
    String? reason;
    if (!approve) {
      reason = await _askReason('educational resource', title);
      if (reason == null) return;
    }
    try {
      final adminId = FirebaseAuth.instance.currentUser?.uid;
      final changes = <String, dynamic>{
        'status': approve ? 'approved' : 'rejected',
        'updatedAt': FieldValue.serverTimestamp(),
        if (approve) ...{
          'approvedAt': FieldValue.serverTimestamp(),
          'approvedBy': adminId,
          'rejectionReason': FieldValue.delete(),
        } else ...{
          'rejectedAt': FieldValue.serverTimestamp(),
          'rejectedBy': adminId,
          'rejectionReason': reason,
        },
      };
      await _firestore.collection('educationalResources').doc(id).update(changes);
      _message(approve ? 'Resource approved.' : 'Resource rejected.');
    } catch (e) {
      _message('Could not update resource: $e');
    }
  }

  void _showDetails(String heading, Map<String, dynamic> data) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(heading, maxLines: 2, overflow: TextOverflow.ellipsis),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: data.entries.map((entry) {
                final value = entry.value;
                String display;
                if (value is Timestamp) {
                  display = value.toDate().toLocal().toString();
                } else if (value is Map || value is List) {
                  display = value.toString();
                } else {
                  display = _text(value);
                }
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_prettyKey(entry.key),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryDark)),
                      const SizedBox(height: 3),
                      SelectableText(display),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _prettyKey(String key) {
    final spaced = key.replaceAllMapped(
      RegExp(r'([a-z])([A-Z])'),
      (match) => '${match[1]} ${match[2]}',
    );
    return spaced[0].toUpperCase() + spaced.substring(1);
  }

  Widget _searchAndFilter({required bool hasStatusFilter}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search by name, email, title, category…',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                      icon: const Icon(Icons.clear),
                    ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          if (hasStatusFilter) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 8,
                children: ['All', 'pending', 'approved', 'rejected'].map((status) {
                  final selected = _statusFilter == status;
                  return ChoiceChip(
                    label: Text(status == 'All'
                        ? 'All statuses'
                        : '${status[0].toUpperCase()}${status.substring(1)}'),
                    selected: selected,
                    onSelected: (_) => setState(() => _statusFilter = status),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _empty(String message) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.search_off_rounded,
                  size: 46, color: AppTheme.textGrey),
              const SizedBox(height: 10),
              Text(message, textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.textGrey)),
            ],
          ),
        ),
      );

  Widget _error(Object error) => Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text('Unable to load data.\n$error', textAlign: TextAlign.center),
        ),
      );

  Widget _statusBadge(String status) {
    final color = switch (status) {
      'approved' => AppTheme.pastelGreen,
      'rejected' => const Color(0xFFFFE0E0),
      _ => AppTheme.pastelYellow,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
      child: Text(status.toUpperCase(),
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _userTab() {
    return Column(
      children: [
        _searchAndFilter(hasStatusFilter: false),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _firestore.collection('users').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) return _error(snapshot.error!);
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final query = _searchController.text.trim();
              final docs = snapshot.data!.docs.where((doc) => _matches(doc.data(), query)).toList();
              docs.sort((a, b) => _text(a.data()['name'], _text(a.data()['displayName'], '')).toLowerCase()
                  .compareTo(_text(b.data()['name'], _text(b.data()['displayName'], '')).toLowerCase()));
              if (docs.isEmpty) return _empty('No users found.');
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final data = doc.data();
                  final name = _text(data['name'], _text(data['displayName'], 'Unnamed user'));
                  final email = _text(data['email']);
                  final role = _text(data['role'], 'user');
                  return Card(
                    color: Colors.white,
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: Color(0xFFE6EBE7)),
                    ),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: AppTheme.pastelBlue,
                        child: Icon(Icons.person_outline, color: AppTheme.primaryDark),
                      ),
                      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text('$email\nRole: $role', maxLines: 2, overflow: TextOverflow.ellipsis),
                      isThreeLine: true,
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showDetails('User details', {'documentId': doc.id, ...data}),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _expertTab() {
    return Column(
      children: [
        _searchAndFilter(hasStatusFilter: true),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _firestore.collection('experts').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) return _error(snapshot.error!);
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final query = _searchController.text.trim();
              final docs = snapshot.data!.docs.where((doc) {
                final data = doc.data();
                final status = _text(data['status'], 'pending');
                return ( _statusFilter == 'All' || status == _statusFilter) && _matches(data, query);
              }).toList();
              docs.sort((a, b) => _text(a.data()['name']).toLowerCase().compareTo(_text(b.data()['name']).toLowerCase()));
              if (docs.isEmpty) return _empty('No experts match your search and filter.');
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final data = doc.data();
                  final name = _text(data['name'], 'Unnamed expert');
                  final status = _text(data['status'], 'pending');
                  final subtitle = '${_text(data['expertType'], 'Expert')} • ${_text(data['qualification'])}';
                  return Card(
                    color: Colors.white,
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFFE6EBE7))),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        children: [
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const CircleAvatar(backgroundColor: AppTheme.pastelGreen, child: Icon(Icons.medical_services_outlined, color: AppTheme.primaryDark)),
                            title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('$subtitle\n${_text(data['email'])}', maxLines: 3, overflow: TextOverflow.ellipsis),
                            isThreeLine: true,
                            trailing: _statusBadge(status),
                            onTap: () => _showDetails('Expert profile', {'documentId': doc.id, ...data}),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Wrap(
                              spacing: 8,
                              children: [
                                TextButton.icon(
                                  onPressed: () => _showDetails('Expert profile', {'documentId': doc.id, ...data}),
                                  icon: const Icon(Icons.visibility_outlined, size: 18), label: const Text('Details'),
                                ),
                                if (status != 'approved') FilledButton.tonalIcon(
                                  onPressed: () => _setExpertStatus(id: doc.id, name: name, approve: true),
                                  icon: const Icon(Icons.check, size: 18), label: const Text('Approve'),
                                ),
                                if (status != 'rejected') TextButton.icon(
                                  onPressed: () => _setExpertStatus(id: doc.id, name: name, approve: false),
                                  icon: const Icon(Icons.close, size: 18), label: const Text('Reject'),
                                  style: TextButton.styleFrom(foregroundColor: Colors.red.shade700),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _resourceTab() {
    return Column(
      children: [
        _searchAndFilter(hasStatusFilter: true),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _firestore.collection('educationalResources').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) return _error(snapshot.error!);
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final query = _searchController.text.trim();
              final docs = snapshot.data!.docs.where((doc) {
                final data = doc.data();
                final status = _text(data['status'], 'pending');
                return (_statusFilter == 'All' || status == _statusFilter) && _matches(data, query);
              }).toList();
              docs.sort((a, b) {
                final ta = a.data()['createdAt'];
                final tb = b.data()['createdAt'];
                if (ta is Timestamp && tb is Timestamp) return tb.compareTo(ta);
                return 0;
              });
              if (docs.isEmpty) return _empty('No resources match your search and filter.');
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final data = doc.data();
                  final title = _text(data['title'], 'Untitled resource');
                  final status = _text(data['status'], 'pending');
                  return Card(
                    color: Colors.white,
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFFE6EBE7))),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        children: [
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const CircleAvatar(backgroundColor: AppTheme.pastelYellow, child: Icon(Icons.menu_book_outlined, color: AppTheme.primaryDark)),
                            title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('${_text(data['category'], 'General')} • By ${_text(data['expertName'], 'Unknown expert')}\n${_text(data['shortDescription'], '')}', maxLines: 3, overflow: TextOverflow.ellipsis),
                            isThreeLine: true,
                            trailing: _statusBadge(status),
                            onTap: () => _showDetails('Resource details', {'documentId': doc.id, ...data}),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Wrap(
                              spacing: 8,
                              children: [
                                TextButton.icon(
                                  onPressed: () => _showDetails('Resource details', {'documentId': doc.id, ...data}),
                                  icon: const Icon(Icons.visibility_outlined, size: 18), label: const Text('Preview'),
                                ),
                                if (status != 'approved') FilledButton.tonalIcon(
                                  onPressed: () => _setResourceStatus(id: doc.id, title: title, approve: true),
                                  icon: const Icon(Icons.check, size: 18), label: const Text('Approve'),
                                ),
                                if (status != 'rejected') TextButton.icon(
                                  onPressed: () => _setResourceStatus(id: doc.id, title: title, approve: false),
                                  icon: const Icon(Icons.close, size: 18), label: const Text('Reject'),
                                  style: TextButton.styleFrom(foregroundColor: Colors.red.shade700),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Management Centre'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.people_outline), text: 'Users'),
            Tab(icon: Icon(Icons.medical_services_outlined), text: 'Experts'),
            Tab(icon: Icon(Icons.menu_book_outlined), text: 'Resources'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_userTab(), _expertTab(), _resourceTab()],
      ),
    );
  }
}
