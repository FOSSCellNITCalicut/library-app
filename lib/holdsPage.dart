import 'package:flutter/material.dart';
import 'package:library_nitc/auth_provider.dart';
import 'package:library_nitc/user_provider.dart';
import 'package:provider/provider.dart';

class HoldsPage extends StatefulWidget {
  @override
  State<HoldsPage> createState() => _HoldsPageState();
}

class _HoldsPageState extends State<HoldsPage> {
  final Set<String> _cancelling = {};

  @override
  void initState() {
    super.initState();
    final token = context.read<AuthProvider>().accessToken;
    if (token != null) {
      context.read<UserProvider>().fetchHolds(token);
    }
  }

  Future<void> _confirmCancel(HoldItem hold) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Cancel hold?"),
        content: Text("Cancel your hold on \"${hold.title}\"?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("No"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Yes, cancel hold"),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final token = context.read<AuthProvider>().accessToken;
    if (token == null) return;

    setState(() => _cancelling.add(hold.reserveId));
    try {
      final result = await context.read<UserProvider>().cancelHold(token, hold.reserveId);
      if (!mounted) return;
      if (!result.success) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message)));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not cancel hold. Try again later.")),
      );
    } finally {
      if (mounted) setState(() => _cancelling.remove(hold.reserveId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_sharp),
        ),
        title: const Text("Your Holds"),
      ),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, _) => _buildBody(userProvider),
      ),
    );
  }

  Widget _buildBody(UserProvider userProvider) {
    if (userProvider.holdsLoading && userProvider.holds == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (userProvider.holdsError != null && userProvider.holds == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(userProvider.holdsError!),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                final token = context.read<AuthProvider>().accessToken;
                if (token != null) context.read<UserProvider>().fetchHolds(token);
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final holds = userProvider.holds ?? [];
    if (holds.isEmpty) {
      return const Center(
        child: Text('No active holds.', style: TextStyle(color: Colors.black54)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: holds.length,
      itemBuilder: (context, index) {
        final hold = holds[index];
        final cancelling = _cancelling.contains(hold.reserveId);

        return Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Colors.purple.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hold.title.isNotEmpty ? hold.title : 'Untitled hold',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    if (hold.branch.isNotEmpty)
                      Text("Pickup: ${hold.branch}", style: const TextStyle(color: Colors.black54)),
                    if (hold.status.isNotEmpty)
                      Text("Status: ${hold.status}", style: const TextStyle(color: Colors.black54)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: cancelling ? null : () => _confirmCancel(hold),
                child: cancelling
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text("Cancel"),
              ),
            ],
          ),
        );
      },
    );
  }
}
