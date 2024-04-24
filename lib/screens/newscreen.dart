import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class favorites extends StatefulWidget {
  const favorites({Key? key}) : super(key: key);

  @override
  State<favorites> createState() => _favoritesState();
}

class _favoritesState extends State<favorites> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("My Favorite Places"),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('favoritePlace').snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot){
          if(snapshot.connectionState == ConnectionState.waiting){
            return Center(
              child: CircularProgressIndicator(),
            );
          }
          final places = snapshot.data!.docs;
          return ListView.builder(
            itemCount: places.length,
            itemBuilder: (context, index){
              final place = places[index];

              TextEditingController nameController = TextEditingController();
              TextEditingController detailsController = TextEditingController();

              nameController.text = place['Name Place'];
              detailsController.text = place['detail'];
              return Card(
                elevation: 3, // Add elevation
                margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16), // Add margin
                child: ListTile(
                  title: Text(
                    place['Name Place'],
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  subtitle: Text(
                    place['detail'],
                    style: TextStyle(fontSize: 16),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () async {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text("Edit Place Description"),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextField(
                                    controller: nameController,
                                    decoration: InputDecoration(labelText: 'Place Name'),
                                  ),
                                  Gap(10),
                                  TextField(
                                    controller: detailsController,
                                    decoration: InputDecoration(labelText: 'Place Description'),
                                  ),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  child: Text('Cancel'),
                                ),
                                ElevatedButton( // Change button style
                                  onPressed: () async {
                                    try {
                                      await FirebaseFirestore.instance.collection('favoritePlace').doc(place.id).update({
                                        'Name Place': nameController.text,
                                        'detail': detailsController.text,
                                      });
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Place description successfully updated'),
                                        ),
                                      );
                                      Navigator.pop(context);
                                    } catch (e) {
                                      print('Error updating place description: $e');
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Failed to update place description. Please try again.'),
                                        ),
                                      );
                                    }
                                  },
                                  child: Text('Update'),
                                ),
                              ],
                            ),
                          );
                        },
                        icon: Icon(Icons.edit),
                      ),
                      IconButton(
                        onPressed: (){
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text("Confirm Deletion"),
                              content: Text("Are you sure you want to delete (${place['Name Place']}) from your favorite places?"),
                              actions: [
                                TextButton(
                                  onPressed: () async {
                                    Navigator.of(context).pop();
                                  },
                                  child: Text("Cancel"),
                                ),
                                ElevatedButton( // Change button style
                                  onPressed: () async {
                                    await FirebaseFirestore.instance.collection('favoritePlace').doc(place.id).delete();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text("${place['Name Place']} successfully deleted"),
                                      ),
                                    );
                                    Navigator.of(context).pop();
                                  },
                                  child: Text("Confirm"),
                                ),
                              ],
                            ),
                          );
                        },
                        icon: Icon(Icons.delete),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }
      ),
    );
  }
}
