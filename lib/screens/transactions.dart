import 'package:nova_system/util/data.dart';
import 'package:flutter/material.dart';


class Transactions extends StatefulWidget {
  const Transactions({Key? key}) : super(key: key);

  @override
  _TransactionsState createState() => _TransactionsState();
}

class _TransactionsState extends State<Transactions> {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      cacheExtent: 20,
      physics: const NeverScrollableScrollPhysics(),
      primary: false,
      shrinkWrap: true,
      itemCount: transactions.length,
      itemBuilder: (BuildContext context, int index) {
        Map transaction = transactions[index];
        return Card(
          elevation: 4,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(10),
            ),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundImage: AssetImage(
                transaction['dp'],
              ),
              radius: 25,
            ),
            title: Text(transaction['name']),
            subtitle: Text(transaction['date']),
            trailing: Text(
              transaction['type'] == "sent"
                  ?"-${transaction['amount']}"
                  :"+${transaction['amount']}",
              style: TextStyle(
                color: transaction['type'] == "sent"
                    ?Colors.red
                    :Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },

    );
  }
}
