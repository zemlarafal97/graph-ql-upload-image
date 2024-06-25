import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

void main() {
  runApp(MaterialApp(
    title: "GQL App",
    home: MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final HttpLink httpLink = HttpLink("https://countries.trevorblades.com/");
    final ValueNotifier<GraphQLClient> client = ValueNotifier<GraphQLClient>(
      GraphQLClient(
        link: httpLink as Link,
        cache: GraphQLCache(),
      ),
    );
    return GraphQLProvider(
      client: client,
      child: HomePage(),
    );
  }
}

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
