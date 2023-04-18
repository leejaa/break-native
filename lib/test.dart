import 'package:flutter/material.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<String> _list = ['Apple', 'Banana', "Strawberry", "Watermelon"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('RefreshIndicator')),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _list = [..._list, ..._list];
          });
        },
        child: ListView.builder(
          itemCount: _list.length,
          itemBuilder: (context, index) {
            return ListTile(
              title: Text(_list[index]),
            );
          },
        ),
      ),
    );
  }
}
