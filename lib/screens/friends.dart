import 'package:flutter/material.dart';
import '../services/user_service.dart';
import '../models/user_info.dart';  // UserInfo ve FriendRequest modelleri

class FriendsPage extends StatefulWidget {
  const FriendsPage({Key? key}) : super(key: key);

  @override
  _FriendsPageState createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  late Future<List<UserInfo>> _friendsFuture;

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  void _loadFriends() {
    _friendsFuture = UserService.getFriends();
  }

  Future<void> _onAddPressed() async {
    final username = await showDialog<String>(
      context: context,
      builder: (ctx) {
        String input = '';
        return AlertDialog(
          title: const Text('Arkadaş Kullanıcı Adı'),
          content: TextField(
            decoration: const InputDecoration(hintText: 'username girin'),
            onChanged: (v) => input = v.trim(),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, input), child: const Text('Ekle')),
          ],
        );
      },
    );

    if (username == null || username.isEmpty) return;

    final user = await UserService.findUserByUsername(username);
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Kullanıcı bulunamadı')));
      return;
    }

    await UserService.sendFriendRequest(user.id);
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Arkadaşlık isteği gönderildi'))
    );

  }

  void _goToRequests() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FriendRequestsPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<UserInfo>>(
      future: _friendsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Arkadaşlar'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications),
                  onPressed: _goToRequests,
                ),
              ],
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final friends = snapshot.data ?? [];

        return Scaffold(
          appBar: AppBar(
            title: const Text('Arkadaşlar'),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: _goToRequests,
              ),
            ],
          ),
          body: friends.isEmpty
              ? Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Hiç arkadaşın yok :(',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                FloatingActionButton(
                  onPressed: _onAddPressed,
                  child: const Icon(Icons.add),
                ),
              ],
            ),
          )
              : ListView.builder(
            itemCount: friends.length,
            itemBuilder: (ctx, i) {
              final f = friends[i];
              return ListTile(
                title: Text(f.username),
                subtitle: Text(f.email),
              );
            },
          ),
          floatingActionButton: friends.isEmpty
              ? null
              : FloatingActionButton(
            onPressed: _onAddPressed,
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}

class FriendRequestsPage extends StatefulWidget {
  const FriendRequestsPage({Key? key}) : super(key: key);

  @override
  _FriendRequestsPageState createState() => _FriendRequestsPageState();
}

class _FriendRequestsPageState extends State<FriendRequestsPage> {
  late Future<List<FriendRequest>> _reqsFuture;

  @override
  void initState() {
    super.initState();
    _reqsFuture = UserService.getFriendRequests();
  }

  Future<void> _respond(int reqId, bool accept) async {
    await UserService.respondFriendRequest(reqId, accept);
    setState(() => _reqsFuture = UserService.getFriendRequests());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Arkadaş İstekleri')),
      body: FutureBuilder<List<FriendRequest>>(
        future: _reqsFuture,
        builder: (ctx, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final reqs = snap.data ?? [];
          if (reqs.isEmpty) {
            return const Center(child: Text('Yeni istek yok'));
          }
          return ListView(
            children: reqs.map((r) => ListTile(
              title: Text(r.fromUsername),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.check),
                    onPressed: () => _respond(r.id, true),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => _respond(r.id, false),
                  ),
                ],
              ),
            )).toList(),
          );
        },//deneme git için
      ),
    );
  }
}
