import 'package:flutter/material.dart';
import 'package:library_nitc/auth_provider.dart';
import 'package:library_nitc/user_provider.dart';
import 'package:persistent_bottom_nav_bar_v2/persistent_bottom_nav_bar_v2.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

// Public OPAC URL, matches the backend's default KOHA_OPAC_URL.
const String _opacBaseUrl = 'https://opac.nitc.ac.in';

class PaymentHistoryPage extends StatefulWidget {
  @override
  State<PaymentHistoryPage> createState() => _PaymentHistoryPageState();
}

class _PaymentHistoryPageState extends State<PaymentHistoryPage> {
  @override
  void initState() {
    super.initState();
    final token = context.read<AuthProvider>().accessToken;
    if (token != null) {
      context.read<UserProvider>().fetchFines(token);
      context.read<UserProvider>().fetchFinesHistory(token);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          icon: Icon(Icons.arrow_back_sharp),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(12),
        child: Consumer<UserProvider>(
          builder: (context, userProvider, _) {
            return Column(
              children: [
                Center(
                  child: Text(
                    "History of late payments",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
                  ),
                ),
                SizedBox(height: 25),
                SizedBox(
                  height: 32,
                  child: Row(
                    children: [
                      OutlinedButton(
                        onPressed: () {},
                        style: ButtonStyle(
                          shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              )),
                        ),
                        child: Text("Due Pending:", style: TextStyle(fontWeight: FontWeight.w500)),
                      ),
                      SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: () {},
                        style: ButtonStyle(
                          shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              )),
                        ),
                        child: Text(
                          userProvider.outstandingFine != null
                              ? userProvider.outstandingFine!.toStringAsFixed(0)
                              : "...",
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                      Spacer(),
                      FilledButton.icon(
                        onPressed: () {
                          pushScreenWithNavBar(context, PaymentPage());
                        },
                        style: ButtonStyle(
                          shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              )),
                        ),
                        icon: Icon(Icons.bookmark),
                        label: Text("Pay Now", style: TextStyle(fontWeight: FontWeight.w500)),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                Divider(),
                SizedBox(height: 16),
                Expanded(
                  child: _buildHistoryBody(userProvider),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHistoryBody(UserProvider userProvider) {
    if (userProvider.historyLoading && userProvider.fineHistory == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (userProvider.historyError != null && userProvider.fineHistory == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(userProvider.historyError!),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                final token = context.read<AuthProvider>().accessToken;
                if (token != null) context.read<UserProvider>().fetchFinesHistory(token);
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final items = userProvider.fineHistory ?? [];
    if (items.isEmpty) {
      return const Center(
        child: Text('No fine history.', style: TextStyle(color: Colors.black54)),
      );
    }

    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (BuildContext context, int index) {
        final item = items[index];
        return Container(
          color: Colors.purple.shade100,
          padding: EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.date, style: TextStyle(fontSize: 10)),
                  Text(
                    item.amount.toStringAsFixed(0),
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Text(item.status, style: TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
        );
      },
    );
  }
}

class PaymentPage extends StatefulWidget {
  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  @override
  void initState() {
    super.initState();
    final token = context.read<AuthProvider>().accessToken;
    if (token != null) {
      context.read<UserProvider>().fetchFines(token);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          icon: Icon(Icons.arrow_back_sharp),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(12),
        child: Consumer<UserProvider>(
          builder: (context, userProvider, _) {
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Due pending", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  Text(
                    userProvider.outstandingFine != null
                        ? userProvider.outstandingFine!.toStringAsFixed(0)
                        : "...",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Divider(),
                  SizedBox(height: 8),
                  const _PayOnOpacSection(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Library fine payment happens on the OPAC website, not in-app -- there's no
/// backend support for collecting payment, so this just sends the user there
/// instead of pretending to process a payment.
class _PayOnOpacSection extends StatelessWidget {
  const _PayOnOpacSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Login on the OPAC website and pay your dues there.",
          style: TextStyle(fontSize: 15, color: Colors.black87),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () {
              launchUrl(Uri.parse(_opacBaseUrl), mode: LaunchMode.externalApplication);
            },
            icon: const Icon(Icons.open_in_new),
            label: const Text("Pay Now"),
          ),
        ),
      ],
    );
  }
}
