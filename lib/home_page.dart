import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_firebase/add_new_task.dart';
import 'package:flutter_firebase/utils.dart';
import 'package:flutter_firebase/widgets/date_selector.dart';
import 'package:flutter_firebase/widgets/task_card.dart';
import 'package:intl/intl.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String formatDate(dynamic date) {
    // Ensure the date is a Timestamp and convert it to DateTime
    DateTime dateTime = (date as Timestamp).toDate();

    final DateFormat formatter = DateFormat(
      // 'yyyy-MM-dd HH:mm:ss',
      'yyyy-MM-dd',
    ); // Adjust format as needed
    return formatter.format(dateTime);
  }

  String formatTime(dynamic date) {
    // Convert the Firestore Timestamp to DateTime
    DateTime dateTime = (date as Timestamp).toDate();

    // Format to show only the time (e.g., "10:00 AM")
    final DateFormat formatter = DateFormat(
      'hh:mm a',
    ); // "hh:mm a" will show time in 12-hour format with AM/PM
    return formatter.format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tasks'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddNewTask()),
              );
            },
            icon: const Icon(CupertinoIcons.add),
          ),
        ],
      ),
      body: Center(
        child: Column(
          children: [
            const DateSelector(),
            StreamBuilder(
              stream:
                  FirebaseFirestore.instance
                      .collection("tasks")
                      .where(
                        'creator',
                        isEqualTo: FirebaseAuth.instance.currentUser!.uid,
                      )
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Expanded(
                    child: Center(child: const Text('No data here')),
                  );
                }

                return Expanded(
                  child: ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      return Dismissible(
                        key: ValueKey(index),
                        onDismissed: (direction) async {
                          if (direction == DismissDirection.endToStart) {
                            await FirebaseFirestore.instance
                                .collection("tasks")
                                .doc(snapshot.data!.docs[index].id)
                                .delete();
                          }
                          // Optionally, use setState to force rebuild if needed
                          // setState(() {});
                        },
                        child: Row(
                          children: [
                            Expanded(
                              child: TaskCard(
                                color: hexToColor(
                                  snapshot.data!.docs[index].data()['color'],
                                ),
                                headerText:
                                    snapshot.data!.docs[index].data()['title'],
                                descriptionText:
                                    snapshot.data!.docs[index]
                                        .data()['description'],
                                scheduledDate: formatDate(
                                  snapshot.data!.docs[index].data()['date'],
                                ),
                              ),
                            ),
                            Container(
                              height: 10,
                              width: 10,
                              decoration: BoxDecoration(
                                // color: strengthenColor(
                                //   const Color.fromRGBO(246, 222, 194, 1),
                                //   0.69,
                                // ),
                                color: hexToColor(
                                  snapshot.data!.docs[index].data()['color'],
                                ),
                                shape: BoxShape.circle,
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.all(12.0),
                              child: Text(
                                formatTime(
                                  snapshot.data!.docs[index].data()['date'],
                                ),
                                style: TextStyle(fontSize: 17),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
