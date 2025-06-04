import 'package:easy_upi_payment/easy_upi_payment.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_upi_india/flutter_upi_india.dart';
import 'package:payu_checkoutpro_flutter/payu_checkoutpro_flutter.dart';
import 'package:persistent_bottom_nav_bar_v2/persistent_bottom_nav_bar_v2.dart';
import 'package:upi_payment_qrcode_generator/upi_payment_qrcode_generator.dart';

class PaymentHistoryPage extends StatelessWidget {
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
        child: Column(
          children: [
            Center(child: Text("History of late payments", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),),),
            SizedBox(height: 25,),
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
                          )
                      ),
                    ),
                    child: Text("Due Pending:", style: TextStyle(fontWeight: FontWeight.w500),),
                  ),
                  SizedBox(width: 8,),
                  OutlinedButton(
                    onPressed: () {},
                    style: ButtonStyle(
                      shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          )
                      ),
                    ),
                    child: Text("2000", style: TextStyle(fontWeight: FontWeight.w500),),
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
                          )
                      ),
                    ),
                    icon: Icon(Icons.bookmark),
                    label: Text("Pay Now", style: TextStyle(fontWeight: FontWeight.w500),),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16,),
            Divider(),
            SizedBox(height: 16,),
            Expanded(child: DuesList())
          ],
        ),
      ),
    );
  }
}

class DuesList extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return ListView.builder( // TODO backend
      itemCount: 7,
      itemBuilder: (BuildContext context, int index) {
        return Container(
          color: Colors.purple.shade100,
          padding: EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("12-2-20", style: TextStyle(fontSize: 10),),
              Text("$index 200", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),),
            ],
          ),
        );
      },
    );
  }
}

class PaymentPage extends StatelessWidget {
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
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Due pending", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),),
              Text("2000", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),),
              SizedBox(height: 8,),
              Divider(),
              SizedBox(height: 8,),
              UpiQRSection()
            ],
          ),
        ),
      ),
    );
  }
}

class UpiRequestSection extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _UpiRequestSectionState();

}

class _UpiRequestSectionState extends State<UpiRequestSection>{
  TextEditingController amountController = TextEditingController();
  TextEditingController upiIdController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: amountController,
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Enter Amount'
          ),
        ),
        SizedBox(height: 12,),
        TextField(
          controller: upiIdController,
          decoration: InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Enter UPI ID'
          ),
        ),
        SizedBox(height: 12,),
        TextButton.icon(
          onPressed: () async {

          },
          icon: Icon(Icons.stars),
          label: Text("UPI Request", style: TextStyle(fontWeight: FontWeight.bold),),
          style: TextButton.styleFrom(
            backgroundColor: Colors.purple.shade50,
            foregroundColor: Colors.black54
          )
        )
      ],
    );
  }
}

class UpiQRSection extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _UpiQRSectionState();
}

class _UpiQRSectionState extends State<UpiQRSection> {
  final TextEditingController amountController = TextEditingController();
  var upiDetails = UPIDetails(upiID: 'shriramkiran05@okicici', payeeName: "Shriram Kiran");

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: amountController,
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            labelText: "Enter Amount"
          ),
        ),
        SizedBox(height: 16,),
        TextButton.icon(
            onPressed: () {
              var amount = amountController.text;
              setState(() { // TODO replace with library details
                upiDetails = UPIDetails(upiID: 'shriramkiran05@okicici', payeeName: 'Shriram Kiran', amount: double.tryParse(amount));
              });

            },
            icon: Icon(Icons.stars),
            label: Text("Generate QR", style: TextStyle(fontWeight: FontWeight.bold),),
            style: TextButton.styleFrom(
                backgroundColor: Colors.purple.shade50,
                foregroundColor: Colors.black54
            )
        ),
        SizedBox(height: 16,),
        Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text("Scan code for UPI Payment", style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 16,),
              UPIPaymentQRCode(upiDetails: upiDetails, size: 200,),
              SizedBox(height: 16,),
              Text("Only UPI payment accepted via app", style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 16,),
              Text("*You can pay via cash at library reception", style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        )
      ],
    );
  }
}