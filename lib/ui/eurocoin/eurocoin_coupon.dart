import 'dart:async';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import './eurocoin.dart';

typedef CouponEurocoinItemBodyBuilder<T> = Widget Function(
    CouponEurocoinItem<T> item);
typedef ValueToString<T> = String Function(T value);

class DualHeaderWithHint extends StatelessWidget {
  const DualHeaderWithHint({this.name, this.error, this.showHint});

  final String name;
  final String error;
  final bool showHint;

  Widget _crossFade(Widget first, Widget second, bool isExpanded) {
    return AnimatedCrossFade(
      firstChild: first,
      secondChild: second,
      firstCurve: const Interval(0.0, 0.6, curve: Curves.fastOutSlowIn),
      secondCurve: const Interval(0.4, 1.0, curve: Curves.fastOutSlowIn),
      sizeCurve: Curves.fastOutSlowIn,
      crossFadeState:
          isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(children: <Widget>[
      Expanded(
        flex: 3,
        child: Container(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: DefaultTextStyle(
                style: Theme.of(context).textTheme.subhead, child: Text(name)),
          ),
        ),
      ),
      Expanded(
          flex: 3,
          child: Container(
              margin: const EdgeInsets.only(left: 24.0),
              child: _crossFade(
                  DefaultTextStyle(
                      style: Theme.of(context).textTheme.subhead,
                      child: Text(error, style: TextStyle(color: Colors.red))),
                  DefaultTextStyle(
                      style: Theme.of(context).textTheme.subhead,
                      child: Text("")),
                  showHint)))
    ]);
  }
}

class CollapsibleBody extends StatelessWidget {
  const CollapsibleBody(
      {this.margin = EdgeInsets.zero, this.child, this.onSave, this.onCancel});

  final EdgeInsets margin;
  final Widget child;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextTheme textTheme = theme.textTheme;

    return Column(children: <Widget>[
      Container(
          margin: const EdgeInsets.only(right: 24.0, bottom: 24.0),
          child: Center(
              child: DefaultTextStyle(
                  style: textTheme.caption.copyWith(fontSize: 15.0),
                  child: child))),
      const Divider(height: 1.0),
      Container(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child:
              Row(mainAxisAlignment: MainAxisAlignment.end, children: <Widget>[
            Container(
                margin: const EdgeInsets.only(right: 8.0),
                child: FlatButton(
                    onPressed: onSave,
                    textTheme: ButtonTextTheme.accent,
                    child: const Text('Send'))),
            Container(
                margin: const EdgeInsets.only(right: 8.0),
                child: FlatButton(
                    onPressed: onCancel,
                    child: const Text('Cancel',
                        style: TextStyle(
                            color: Colors.black54,
                            fontSize: 15.0,
                            fontWeight: FontWeight.w500))))
          ]))
    ]);
  }
}

class CouponEurocoinItem<T> {
  CouponEurocoinItem({this.name, this.builder, this.error, this.valueToString});

  final String name;
  String error;
  final CouponEurocoinItemBodyBuilder<T> builder;
  final ValueToString<T> valueToString;
  TextEditingController couponController = new TextEditingController();
  bool isExpanded = false;
  bool isError = false;

  ExpansionPanelHeaderBuilder get headerBuilder {
    return (BuildContext context, bool isExpanded) {
      return DualHeaderWithHint(name: name, error: error, showHint: isExpanded);
    };
  }

  Widget build() => builder(this);
}

var formKey = GlobalKey<FormState>();

class EurocoinCoupon extends StatefulWidget {
  EurocoinCoupon({Key key, this.name, this.email, this.parent})
      : super(key: key);
  final String name;
  final String email;
  final EurocoinHomePageState parent;
  @override
  _EurocoinCouponState createState() => _EurocoinCouponState();
}

class _EurocoinCouponState extends State<EurocoinCoupon> {
  List<CouponEurocoinItem<dynamic>> _couponEurocoinItem;
  FirebaseUser currentUser;

  @override
  void initState() {
    super.initState();

    _couponEurocoinItem = <CouponEurocoinItem<dynamic>>[
      CouponEurocoinItem<String>(
        name: 'Redeem Coupon',
        error: '',
        valueToString: (String value) => value,
        builder: (CouponEurocoinItem<String> item) {
          void close() {
            setState(() {
              item.isExpanded = false;
            });
          }

          return Form(
            key: formKey,
            child: Builder(
              builder: (BuildContext context) {
                return CollapsibleBody(
                    margin: const EdgeInsets.symmetric(horizontal: 16.0),
                    onSave: () {
                      if (formKey.currentState.validate()) {
                        String coupon = item.couponController.text;
                        Future<int> result = couponEurocoin(coupon);
                        result.then((value) {
                          print(value);
                          if (value == 0) {
                            setState(() {
                              item.error = "Successful!";
                            });
                            widget.parent.getUserEurocoin();
                          } else if (value == 2)
                            setState(() {
                              item.error = "Invalid Coupon";
                            });
                          else if (value == 3)
                            setState(() {
                              item.error = "Already Used";
                            });
                          else if (value == 4)
                            setState(() {
                              item.error = "Coupon Expired";
                            });
                          setState(() {
                            item.couponController.text = '';
                          });
                          Form.of(context).reset();
                          close();
                        });
                      }
                    },
                    onCancel: () {
                      setState(() {
                        item.error = '';
                        item.couponController.text = '';
                      });
                      Form.of(context).reset();
                      close();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: TextFormField(
                          controller: item.couponController,
                          decoration: InputDecoration(
                            labelText: "Coupon Code",
                          ),
                          validator: (val) => val == "" ? val : null),
                    ));
              },
            ),
          );
        },
      )
    ];
  }

  @override
  Widget build(BuildContext context) {
    return new Theme(
        data: new ThemeData(
            brightness: Brightness.light,
            primarySwatch: Colors.indigo,
            platform: Theme.of(context).platform),
        child: SingleChildScrollView(
            child: new DefaultTextStyle(
          style: Theme.of(context).textTheme.subhead,
          child: SafeArea(
            top: false,
            bottom: false,
            child: Container(
              child: Theme(
                  data: Theme.of(context)
                      .copyWith(cardColor: Colors.grey.shade50),
                  child: ExpansionPanelList(
                      expansionCallback: (int index, bool isExpanded) {
                        setState(() {
                          _couponEurocoinItem[index].isExpanded = !isExpanded;
                        });
                      },
                      children: _couponEurocoinItem
                          .map((CouponEurocoinItem<dynamic> item) {
                        return ExpansionPanel(
                          isExpanded: item.isExpanded,
                          headerBuilder: item.headerBuilder,
                          body: item.build(),
                        );
                      }).toList())),
            ),
          ),
        )));
  }

  Future<int> couponEurocoin(String coupon) async {
    var email = widget.email;
    var name = widget.name;
    var bytes = utf8.encode("$email" + "$name");
    var encoded = sha1.convert(bytes);
    String apiUrl =
        "https://eurekoin.avskr.in/api/coupon/$encoded/?code=$coupon";
    print(apiUrl);
    http.Response response = await http.get(apiUrl);
    print(response.body);
    var status = json.decode(response.body)['status'];
    return int.parse(status);
  }
}
