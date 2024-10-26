import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' as convert;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme:
            ColorScheme.fromSeed(seedColor: Color.fromARGB(255, 255, 0, 152)),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Liverpool'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  File? _selectedImage;
  List? _lista;
  List? _listaAnterior;

  @override
  void initState() {
    super.initState();
    getProducts();
  }

  Future<void> getProducts() async {
    var url = Uri.http('10.48.73.189:5000', '/', {'q': '{http}'});
    var response = await http.get(url);
    if (response.statusCode == 200) {
      if (response.statusCode == 200) {
        var jsonResponse = convert.jsonDecode(response.body) as List<dynamic>;
        final lista = jsonResponse;
        setState(() {
          _lista = lista;
          _listaAnterior = lista;
        });
      }
    } else {
      print('Request failed with status: ${response.statusCode}.');
    }
  }

  Future<void> _uploadImage() async {
    if (_selectedImage == null) return;

    final uri = Uri.parse(
        'http://10.48.73.189:5000/search'); // Replace with your server URL
    var request = http.MultipartRequest('POST', uri);

    request.files.add(await http.MultipartFile.fromPath(
      'image', // The name of the form field
      _selectedImage!.path,
    ));

    try {
      final response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await http.Response.fromStream(response);
        setState(() {
          _lista = convert.jsonDecode(responseData.body);
        });

        // Puedes actualizar el estado o hacer lo que necesites con la lista
      } else {}
    } catch (e) {
      // print('Error: $e');
    }
  }

  int _visibleItems = 10;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 211, 0, 144),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            GestureDetector(
              onTap: getProducts,
              child: Image.asset(
                'assets/images/logo.png',
                height: 40,
                fit: BoxFit.fitHeight,
              ),
            ),
            SizedBox(
              width: 400,
              child: TextField(
                onChanged: searchBar,
                decoration: const InputDecoration(
                  suffixIcon: Icon(Icons.search),
                  labelText: 'Buscar',
                  filled: true,
                ),
              ),
            ),
            Row(
              children: [
                IconButton(
                    onPressed: () {
                      _pickImageFromGallery();
                    },
                    icon: Icon(
                      Icons.camera,
                      color: Colors.white,
                    )),
                Text(
                  "Buscar por imagen",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                )
              ],
            )
          ],
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Wrap(
                children: <Widget>[
                  for (var item in _lista!.take(_visibleItems))
                    Container(
                      height: 260,
                      width: 250,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Theme.of(context).colorScheme.inversePrimary,
                          boxShadow: [
                            BoxShadow(
                              color: Color.fromARGB(50, 0, 0, 0),
                              blurRadius: 4,
                              offset: Offset(3, 6)
                            )
                          ]),
                      margin: const EdgeInsets.all(20),
                      child: Column(
                        children: <Widget>[
                          Image.network(
                            item['url'],
                            height: 160,
                            width: 250,
                            fit: BoxFit.fitWidth,
                          ),
                          Text(
                            "${item['Nombre']}\nSKU:${item['SKU']}",
                            textAlign: TextAlign.center,
                          )
                        ],
                      ),
                    ),
                ],
              ),
              if (_visibleItems < _lista!.length)
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _visibleItems += 10;
                    });
                  },
                  child: Text('Cargar más'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void searchBar(String query) {
    final items = _lista!.where((producto) {
      final nombreProducto = producto['Nombre'].toLowerCase();
      final input = query.toLowerCase();

      return nombreProducto.contains(input);
    }).toList();
    setState(() {
      _lista = items;
      if (query.isEmpty) {
        _lista = _listaAnterior;
      }
    });
  }

  Future _pickImageFromGallery() async {
    final returnedImage =
        await ImagePicker().pickImage(source: ImageSource.gallery);

    setState(() {
      _selectedImage = File(returnedImage!.path);
      _uploadImage();
    });
  }
}
