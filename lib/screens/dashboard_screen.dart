import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:notes_app/routing/app_routes.dart';
import 'package:notes_app/screens/auth_screen.dart';
import 'package:notes_app/screens/home_page.dart';
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Widget> screens = [
    HomePage(),
    SizedBox(),
    AddUser(),
    // AuthScreen(),
  ];
  PageController? _pageController;

  @override
  void initState() {
    super.initState();

    _pageController = PageController(initialPage: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Expanded(
        child: PageView.builder(
          itemCount: screens.length,
            scrollDirection: Axis.horizontal,
            controller: _pageController,
            itemBuilder: (context, index) {
          return screens[index];
        }),
      ),
      floatingActionButton: Material(
        child: FloatingActionButton(
          elevation: 6,
          onPressed: () => Get.toNamed(AppRoute.ADD_NEW_NOTE),
          backgroundColor: Theme.of(context).primaryColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(500)),
          child: Icon(Icons.add, color: Theme.of(context).cardColor),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: Container(
        height: 60,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          boxShadow: [BoxShadow(color: Colors.grey[300]!, blurRadius: 10)],
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [

          IconButton(onPressed: ()=> _setPage(0), icon: const Icon(Icons.home)),
          const SizedBox(),
          IconButton(onPressed: ()=> _setPage(2), icon: const Icon(Icons.bookmark_border_outlined)),
        ]),
      ),
    );
  }

  void _setPage(int pageIndex) {
    setState(() {
      _pageController!.jumpToPage(pageIndex);
      // _pageIndex = pageIndex;
    });
  }
}
