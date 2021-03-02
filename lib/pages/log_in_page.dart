import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_swiper/flutter_swiper.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:first_app/navigator/tab_navigator.dart';

class LogInPage extends StatefulWidget {
  @override
  _LogInPageState createState() => _LogInPageState();
}

final _uri = 'http://18.234.144.225:4000/graphql';
final client = GraphQLClient(cache: InMemoryCache(), link: HttpLink(uri: _uri));

class _LogInPageState extends State<LogInPage> {
  TextEditingController _unameController = new TextEditingController();
  TextEditingController _pwdController = new TextEditingController();
  GlobalKey _formKey = new GlobalKey<FormState>();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: new AppBar(
        title: new Text('Log In'),
        leading: new IconButton(
            icon: new Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context);
            }),
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
        child: Form(
          key: _formKey,
          autovalidate: true,
          child: Column(
            children: <Widget>[
              const SizedBox(height: 40),
              TextFormField(
                  style: TextStyle(
                    color: Colors.white,
                  ),
                  autofocus: true,
                  controller: _unameController,
                  decoration: InputDecoration(
                      border: new OutlineInputBorder(
                        gapPadding: 10.0,
                        borderRadius: BorderRadius.circular(20.0),
                        borderSide: BorderSide(
                          color: Color(0xff03DAC5),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Color(0xff03DAC5),
                        ),
                      ),
                      filled: true,
                      fillColor: Color(0xff2d2d2d),
                      labelText: "Username",
                      labelStyle: TextStyle(fontSize: 15, color: Colors.white),
                      hintText: "Username",
                      icon: Icon(Icons.person, color: Colors.white)),
                  validator: (v) {
                    return v.trim().length > 0
                        ? null
                        : "Username can not be empty";
                  }),
              const SizedBox(height: 30),
              TextFormField(
                  style: TextStyle(
                    color: Colors.white,
                  ),
                  controller: _pwdController,
                  decoration: InputDecoration(
                      border: new OutlineInputBorder(
                        gapPadding: 10.0,
                        borderRadius: BorderRadius.circular(20.0),
                        borderSide: BorderSide(
                          color: Color(0xff03DAC5), // 边框颜色
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Color(0xff03DAC5), // 边框颜色
                        ),
                      ),
                      filled: true,
                      fillColor: Color(0xff2d2d2d),
                      labelText: "Password",
                      labelStyle: TextStyle(fontSize: 15, color: Colors.white),
                      hintText: "Password",
                      icon: Icon(Icons.lock, color: Colors.white)),
                  obscureText: true,
                  validator: (v) {
                    return v.trim().length > 5
                        ? null
                        : "password should not less then 5";
                  }),
              // 登录按钮
              const SizedBox(height: 30),
              Text("Trouble logging in?",
                  textAlign: TextAlign.right,
                  style: TextStyle(color: Color(0xff03DAC5))),
              Padding(
                padding: const EdgeInsets.only(top: 28.0),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: RaisedButton(
                        padding: EdgeInsets.all(15.0),
                        child: Text("Log in"),
                        color: Color(0xff03DAC5),
                        textColor: Colors.white,
                        onPressed: () async {
                          if ((_formKey.currentState as FormState).validate()) {
                            final result = await client.query(QueryOptions(
                                documentNode: gql('''
                                query fetchObjectData(\$un: String!, \$pw: String!) {
                                  fetchObjectData(username: \$un, password: \$pw) {
                                    status
                                    message
                                  }
                                }
                              '''),
                                variables: {
                                  'un': _unameController.text,
                                  'pw': _pwdController.text
                                }));
                            if (result.hasException) throw result.exception;
                            print(result.data);
                            print(_unameController.text);
                            print(_pwdController.text);
                            if (result.data["fetchObjectData"]["status"]) {
                              Navigator.push(context,
                                  MaterialPageRoute(builder: (context) {
                                return TabNavigator();
                              }));
                            } else {
                              showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                        title: Text('Error!'),
                                        content: Text(
                                            result.data["fetchObjectData"]
                                                ["message"]),
                                        actions: <Widget>[
                                          new FlatButton(
                                            child: new Text("OK"),
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                            },
                                          ),
                                        ],
                                      ));
                            }
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
