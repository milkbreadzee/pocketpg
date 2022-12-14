import 'package:flutter/material.dart';

class PopularFoodCard extends StatelessWidget {
  const PopularFoodCard({
    Key? key, required this.messname, required this.press,
  }) : super(key: key);

  final String messname;
  final VoidCallback press;

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Container(
      height: 176,
      width: 344,
      child: GestureDetector(
        onTap: press,
        child: Stack(
          children: <Widget>[
            Positioned(
              child: Material(
                child: Container(
                  // width: size * 0.9,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        offset: Offset(0, 6),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ),
      
            Positioned(
              top: 0,
              left: 4,
              child: Card(
                elevation: 10,
                shadowColor: Colors.grey.withOpacity(0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Container(
                  height: 161,
                  width: 145,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10.0),
                    image: const DecorationImage(
                      fit: BoxFit.contain,
                      image: AssetImage("assets/images/burger1.png"),
                    ),
                  ),
                ),
              ),
            ),
      
            Positioned(
              top: 10,
              left: 165,
              child: Container(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "$messname",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Text(
                      "300 for a day",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Text(
                      "Free Delivery\nHomely Food\nNear MEC",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
      
            //new widget here
          ],
        ),
      ),
    );
  }
}

// Container(
//             height: 176,
//             width: 344,
//             child: Row(
//               children: <Widget>[
//                 //const Text("h"),
//                 Align(
//                   alignment: Alignment.centerLeft,
//                   child: Image.asset("assets/images/foodimg.png"),
//                 ),
//                 RichText(
//                   text: TextSpan(
//                     children: [
//                       TextSpan(
//                         text: "Vindy Mess\n".toUpperCase(),
//                         style: const TextStyle(
//                           fontSize: 14,
//                           fontWeight: FontWeight.w500,
//                           color: Colors.black,
//                         ),
//                       ),
//                       TextSpan(
//                         text: "\$10 for a day",
//                         style: const TextStyle(
//                           fontSize: 11,
//                           fontWeight: FontWeight.w400,
//                           color: Colors.black,
//                         ),
//                       ),
//                     ],
//                   ),
//                 )
//               ],
//             ),
//           ),
        