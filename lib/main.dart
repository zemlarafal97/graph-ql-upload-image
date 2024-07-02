import 'dart:io';

import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:http/http.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

void main() async {
  final HttpLink httpLink = HttpLink(
    'https://your-graphql-endpoint.com/graphql',
  );

  ValueNotifier<GraphQLClient> client = ValueNotifier(
    GraphQLClient(
      link: httpLink,
      cache: GraphQLCache(),
    ),
  );

  runApp(MyApp(client: client));
}

class MyApp extends StatelessWidget {
  final ValueNotifier<GraphQLClient> client;

  const MyApp({super.key, required this.client});

  @override
  Widget build(BuildContext context) {
    return GraphQLProvider(
      client: client,
      child: const MaterialApp(
        home: UploadImageScreen(),
      ),
    );
  }
}

class UploadImageScreen extends StatefulWidget {
  const UploadImageScreen({super.key});

  @override
  State<UploadImageScreen> createState() => _UploadImageScreenState();
}

class _UploadImageScreenState extends State<UploadImageScreen> {
  File? _image;
  final picker = ImagePicker();

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      } else {
        print('No image selected.');
      }
    });
  }

  Future<void> _uploadImage() async {
    if (_image == null) return;

    final url = Uri.parse('https://your-graphql-endpoint.com/upload');
    final request = http.MultipartRequest('POST', url)
      ..files.add(await http.MultipartFile.fromPath('file', _image!.path));

    final response = await request.send();

    if (response.statusCode == 200) {
      print('Image uploaded!');
    } else {
      print('Upload failed!');
    }
  }

  Future<void> _sendImageMutation() async {
    if (_image == null) return;

    const String uploadImageMutation = """
      mutation UploadImage(\$file: Upload!) {
        uploadImage(file: \$file) {
          url
        }
      }
    """;

    final client = GraphQLProvider.of(context).value;

    final bytes = await _image!.readAsBytes();

    final multipartFile = MultipartFile.fromBytes(
      'file',
      bytes,
      filename: _image!.path.split('/').last,
    );

    final result = await client.mutate(
      MutationOptions(
        document: gql(uploadImageMutation),
        variables: {
          'file': multipartFile,
        },
      ),
    );

    if (result.hasException) {
      print('Upload failed: ${result.exception.toString()}');
    } else {
      print('Upload success: ${result.data}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Upload Image"),
        backgroundColor: Colors.amber,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _image == null
                ? Text('No image selected.')
                : Container(
                    width: 400,
                    height: 400,
                    child: Image.file(_image!),
                  ),
            ElevatedButton(
              onPressed: _pickImage,
              child: Text("Pick Image"),
            ),
            ElevatedButton(
              onPressed: _uploadImage,
              child: Text("Upload Image (legacy http)"),
            ),
            ElevatedButton(
              onPressed: _sendImageMutation,
              child: Text("Upload Image (GraphQL mutation)"),
            ),
          ],
        ),
      ),
    );
  }
}

/*
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("GraphQL Client"),
      ),
      body: Query(
        options: QueryOptions(
          document: gql(
            r"""
            query GetContinent($code : ID!){
 	            continent(code:$code){
                name
                countries{
                  name
                }
              }
            }
       """,
          ),
          variables: <String,dynamic> {
            "code": "EU"
          }
        ),
        builder: (
          QueryResult result, {
          VoidCallback? refetch,
          FetchMore? fetchMore,
        }) {
          if (result.hasException) {
            return Text(result.exception.toString());
          }
          if (result.data == null) {
            return Text("No Data Found!");
          }
          return ListView.builder(
            itemBuilder: (BuildContext context, int index) {
              return ListTile(
                title: Text(result.data?['continent']['countries'][index]['name']),
              );
            },
            itemCount: result.data?['continent']['countries'].length,
          );
        },
      ),
    );
  }
}
*/
